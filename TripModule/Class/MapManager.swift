//
//  MapManager.swift
//  TripModule
//
//  Created by Gabriel Elfassi on 12/08/2019.
//  Copyright © 2019 Gabriel Elfassi. All rights reserved.
//

import Foundation
import UIKit
import MapKit

/**
    Map view management
 */
class MapManager {
    
    /**
        List concerning location choose by user
     */
    public var locationList:[Location] = []
    
    /**
        List of distance between each point
     */
    public var distancePaths:[Double] = []
    
    /**
     List of customer/adress:
        0. Identifiant
        1. Location
     */
    public var customers:[(String, CLLocationCoordinate2D)] = []
    
    /**
     Total travel time of trip
     */
    public var travelTime:Double = 0.0
    
    /**
        Return if mapview is in standard type
     */
    public func isStandardMapType(_ mapView:MKMapView) -> Bool {
        return mapView.mapType == MKMapType.standard
    }
    
    /**
        Zoom In Or Out compare to an Int set argument
        - set = 0 => zoom in
        - set > 0 => zoom out
     */
    public func zoomIntoSelectedMap(_ mapView:MKMapView,inOrOut set:Int) {
        var region: MKCoordinateRegion = mapView.region
        if set == 0 {
            region.span.latitudeDelta /= 5.0
            region.span.longitudeDelta /= 5.0
        } else {
            region.span.latitudeDelta = min(region.span.latitudeDelta * 2.0, 180.0)
            region.span.longitudeDelta = min(region.span.longitudeDelta * 2.0, 180.0)
        }
        mapView.setRegion(region, animated: true)
    }
    
    /**
        Zoom on specific location
     */
    public func zoomOnSpecificLocation(_ mapView:MKMapView,specificLocation location:CLLocationCoordinate2D) {
        let latDelta:CLLocationDegrees = 0.01
        let lngDelta:CLLocationDegrees = 0.01
        
        let span:MKCoordinateSpan = MKCoordinateSpan.init(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        
        mapView.setRegion(MKCoordinateRegion.init(center: location, span: span), animated: true)
    }
    
    
    /**
        Crop map view trip for displaying each annotation once
        Convert CGPoint to CLLocationCoordinate in order to disp annotations
     */
    public func cropMapViewTrip(_ mapView:MKMapView) {
        mapView.showAnnotations(mapView.annotations, animated: false)
        
        let movement = CGPoint(x: mapView.center.x / 2, y: mapView.center.y)
        let coordinate: CLLocationCoordinate2D = mapView.convert(movement, toCoordinateFrom:mapView)
        mapView.setCenter(coordinate, animated: false) // change the ne
        
        zoomIntoSelectedMap(mapView, inOrOut: 1)
    }
    
    /**
        Set image from annotation map view
     */
    public func setImageAnnotation(_ mapView: MKMapView, viewFor annotation: MKAnnotation, annotationImage:UIImage, identifier:String) -> MKAnnotationView?{
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            // go ahead and use forced unwrapping and you'll be notified if it can't be found; alternatively, use `guard` statement to accomplish the same thing and show a custom error message
            annotationView!.image = annotationImage
        } else {
            annotationView!.annotation = annotation
        }
        annotationView!.canShowCallout = true
        
        return annotationView
    }
    
    /**
        Zoom and display annotation of selected search completion
     */
    public func didSelectedCompletion(mapView:MKMapView, response:MKLocalSearch.Response, completion:MKLocalSearchCompletion) {
        let location = response.mapItems[0].placemark.coordinate
        
        if #available(iOS 11.0, *) {
            //TODO: Afficher l'annotation ici
            let annotationM = AdressAnnotation(coordinate: location, identifier: "\(completion.title)")
            mapView.addAnnotation(annotationM)
        } else {
            // Fallback on earlier versions
        }
        self.zoomOnSpecificLocation(mapView, specificLocation: location)
    }
    
    /**
        Add pin on map from long pressure with location argument
     */
    public func addPinOnMap(_ sender:UILongPressGestureRecognizer, mapView:MKMapView, location:@escaping (Location) -> ())  {
        let touchPoint = sender.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude), completionHandler: {(placemarks, error) -> Void in
            if error != nil {
                print("Reverse geocoder failed with error", error!.localizedDescription)
                return
            }
            
            if placemarks!.count > 0 {
                let pm = placemarks![0]
                let annotation = AdressAnnotation(coordinate: newCoordinates, identifier: "\((pm.thoroughfare) ?? "Unknown place")")
                
                let loc = Location(id: "\((pm.thoroughfare) ?? "Unknown place")", adress: "\((pm.thoroughfare) ?? "Unknown place"), \(pm.subLocality ?? "Unknonw city")", coordinate: newCoordinates)
                mapView.addAnnotation(annotation)
                location(loc)
            }
            else {
                let annotation = AdressAnnotation(coordinate: newCoordinates, identifier: "Unknown place")
                mapView.addAnnotation(annotation)
                print("Problem with the data received from geocoder")
            }
            
        })
    }
    
    /**
        Get duration from 2 points with completion handler
     */
    public func getDurationFromTwoPoints(src: CLLocationCoordinate2D, dst: CLLocationCoordinate2D,_ isSelectedGraph:Bool = false, completion: @escaping (Double) -> Void) {
        // source and destination are the relevant MKMapItems
        let sourceMapItem = MKMapItem(placemark: MKPlacemark(coordinate: src))
        let destinationMapItem = MKMapItem(placemark: MKPlacemark(coordinate:dst))
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        // Calculate the direction
        let directions = MKDirections(request: directionRequest)
        directions.calculate {
            (response, error) -> Void in
            
            guard let response = response else {
                return
            }
            
            // pour obtenir un resultat précis
            let route = response.routes[0]
            let duration = route.expectedTravelTime
            self.travelTime += (duration / 60)
            completion(duration)
        }
    }
    
    /**
     On initialise le graph par un parcours donné
     */
    public func InitSelectedGraph(mapView:MKMapView, tableView:UITableView, points:[(String,CLLocationCoordinate2D)], _ travelTimeLabel:UILabel, _ arrivalTimeLabel:UILabel) {
        travelTime = 0
        mapView.removeAnnotations(mapView.annotations)
        mapView.removeOverlays(mapView.overlays)
        for i in 0..<points.count - 1 {
            // on calcule la distance entre chaque point
            let src = points[i].1
            let dst = points[i+1].1
            let distance = DistanceCalculator().distanceCalculator(p1: src, p2: dst)
            distancePaths.append(distance)
            // on calcule la durée entre chaque point
            self.showRouteOnMap(mapView: mapView, pickupCoordinate: points[i].1, destinationCoordinate: points[i+1].1, idSrc: points[i].0, idDst: points[i+1].0)
            self.getDurationFromTwoPoints(src: src, dst: dst) { (duration) in
                self.travelTime += duration
                let date = Date() // save date, so all components use the same date
                let calendar = Calendar.current // or e.g. Calendar(identifier: .persian)
                
                let tupleHM = self.minutesToHoursMinutes(minutes: Int(self.travelTime / 60))
                print(tupleHM)
                var hour = (calendar.component(.hour, from: date) + tupleHM.hours) % 24
                var minutes = calendar.component(.minute, from: date) + tupleHM.leftMinutes
                print(hour, minutes)
                // add one hour if minute are > 60
                if minutes > 59 {
                    hour += 1
                    minutes = minutes % 60
                }
                arrivalTimeLabel.text = "\(hour)h\(minutes)"
                travelTimeLabel.text = "\(Int(self.travelTime / 60)) min"
            }   
        }
        tableView.reloadData()
    }
    
    /**
     Graph initialisation
     */
    public func InitGraph(mapView:MKMapView, tableView:UITableView, _ points:[(String,CLLocationCoordinate2D)], _ travelTimeLabel:UILabel, _ arrivalTimeLabel:UILabel) {
        travelTime = 0
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        var graph = Graph()
        var tupleArray:[(Int,Int,Double)] = [] // 1:i, 2:j, 3:Distance,
        var matrixTime:[[Double]] = [] // matrice representant le temps entre chaque noeud
        var matrix:[[Double]] = []
        // 1. On calcule la distance entre chaque points
        for i in 0..<points.count {
            // on initialise par la même occasion les matrice durée et distance
            matrix.append([])
            matrixTime.append([])
            for j in 0..<points.count {
                matrix[i].append(0.0)
                matrixTime[i].append(0.0)
                if i != j {
                    let src = points[i].1
                    let dst = points[j].1
                    let distance = DistanceCalculator().distanceCalculator(p1: src, p2: dst)
                    tupleArray.append((i,j,distance))
                }
            }
        }
        
        // 2. On en déduit le chemin le plus optimisé
        for index in 0..<tupleArray.count {
            let i = tupleArray[index].0
            let j = tupleArray[index].1
            matrix[i][j] = tupleArray[index].2
        }
        graph = Graph(order: points.count, adjMatrix: matrix)
        let paths = graph.GetShortestPath()
        
        for i in 0..<paths.count - 1 {
            let src = paths[i]
            let dst = paths[i + 1]
            // 3. on calcule la durée entre chaque points
            getDurationFromTwoPoints(src: points[src].1, dst: points[dst].1) { (duration) in
                self.travelTime += duration
                let date = Date() // save date, so all components use the same date
                let calendar = Calendar.current // or e.g. Calendar(identifier: .persian)
                
                let tupleHM = self.minutesToHoursMinutes(minutes: Int(self.travelTime / 60))
                print(tupleHM)
                var hour = (calendar.component(.hour, from: date) + tupleHM.hours) % 24
                var minutes = calendar.component(.minute, from: date) + tupleHM.leftMinutes
                print(hour, minutes)
                // add one hour if minute are > 60
                if minutes > 59 {
                    hour += 1
                    minutes = minutes % 60
                }
                arrivalTimeLabel.text = "\(hour)h\(minutes)"
                travelTimeLabel.text = "\(Int(self.travelTime / 60)) min"
            }
            let distance = matrix[src][dst]
            distancePaths.append(distance)
            
            // 4.  on l'affiche sur la map
            self.showRouteOnMap(mapView: mapView, pickupCoordinate: points[src].1, destinationCoordinate: points[dst].1, idSrc: points[src].0, idDst: points[dst].0)
        }
        
        //On trie les clients dans le collectionview
        var customerTmp = points
        for i in 0..<paths.count {
            customerTmp[i] = points[paths[i]]
        }
        customers = customerTmp
        
        // on convertie les minutes en heure
        //TODO: convertir les minutes en heures et les afficher
        tableView.reloadData()
    }
    
    /**
        Show route on mapview
     */
    public func showRouteOnMap(mapView:MKMapView, pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D, idSrc:String, idDst:String) {
        
        let sourcePlacemark = MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let sourceAnnotation = MKPointAnnotation()
        sourceAnnotation.title = idSrc
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }
        
        let destinationAnnotation = MKPointAnnotation()
        destinationAnnotation.title = idDst
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }
        
        if idSrc == "user_position" {
            mapView.addAnnotations([destinationAnnotation])
        } else {
            mapView.addAnnotations([sourceAnnotation,destinationAnnotation])
        }
        
        
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .automobile
        
        // Calculate the direction
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate {
            (response, error) -> Void in
            
            guard let response = response else {
                if let error = error {
                    print("Erreur lors de l'affichage des routes: \(error)")
                    // si le calcule d'itinineraire est indisponible on affiche uniquement les lignes droites
                    let aPolyline = MKPolyline(coordinates: [pickupCoordinate, destinationCoordinate], count: 2)
                    mapView.addOverlay(aPolyline)
                }
                
                return
            }
            
            let route = response.routes[0]
            
            mapView.addOverlay((route.polyline), level: MKOverlayLevel.aboveRoads)
            
            // On affiche le temps de trajet sur la carte
            for route in response.routes {
                mapView.addOverlay(route.polyline, level: MKOverlayLevel.aboveRoads)
                mapView.setCenter(route.polyline.coordinate, animated: true)
                
                let routeAnnotation = TimeAnnotation(coordinate: route.polyline.points()[route.polyline.pointCount/2].coordinate, identifier: "\(idSrc) to \(idDst)")
                routeAnnotation.time = "\(Int(route.expectedTravelTime / 60)) min"
                
                
                mapView.addAnnotation(routeAnnotation)
            }
            mapView.showAnnotations(mapView.annotations, animated: true)
        }
    }
    
    
    // MARK: private func
    
    /**
     Convert minutes to hours
     */
    private func minutesToHoursMinutes (minutes : Int) -> (hours : Int , leftMinutes : Int) {
        return (minutes / 60, (minutes % 60))
    }

}
