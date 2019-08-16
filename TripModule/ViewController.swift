//
//  ViewController.swift
//  TripModule
//
//  Created by Gabriel Elfassi on 12/08/2019.
//  Copyright © 2019 Gabriel Elfassi. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    // MARK: IBOutlet
    @IBOutlet weak var mapView:MKMapView!
    
    @IBOutlet weak var view_navigate:UIView!
    @IBOutlet weak var image_searching:UIImageView!
    @IBOutlet weak var view_crop:UIView!
    @IBOutlet weak var view_zoom:UIView!
    @IBOutlet weak var view_settings:UIView!
    @IBOutlet weak var view_completion:UIView!
    @IBOutlet weak var view_list:UIView!
    @IBOutlet weak var view_startNavigation:UIView!
    @IBOutlet weak var button_navigation:UIButton!
    @IBOutlet weak var view_details:UIView!
    
    @IBOutlet weak var addPinLongPress:UILongPressGestureRecognizer!
    
    @IBOutlet weak var tableView_completion:UITableView!
    @IBOutlet weak var collectionView_list:UICollectionView!
    @IBOutlet weak var stackView_setNavigation:UIView!
    @IBOutlet weak var textField_navigate:UITextField!
    
    @IBOutlet weak var tableView_details:UITableView!
    @IBOutlet weak var button_cancel:UIButton!
    @IBOutlet weak var button_settings:UIButton!
    @IBOutlet weak var label_travelTime:UILabel!
    @IBOutlet weak var label_arrivalTime:UILabel!
    @IBOutlet weak var label_distance:UILabel!
    
    // MARK: let variables
    private let _mapManager:MapManager = MapManager()
    private let _locationManager = CLLocationManager()
    
    //MARK: var variables
    var searchCompleter = MKLocalSearchCompleter()
    var searchResults = [MKLocalSearchCompletion]()
    var locationList:[Location] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // preliminary settings for map view & location
        _locationManager.requestWhenInUseAuthorization()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.startUpdatingLocation()
        
        mapView.showsUserLocation = true
        mapView.delegate = self
        mapView.showsPointsOfInterest = true
        
        // preliminary settings for table view
        tableView_completion.delegate = self
        tableView_completion.dataSource = self
        
        // preliminary settings for collection view
        collectionView_list.delegate = self
        collectionView_list.dataSource = self
        
        // preliminary settings for textfield
        textField_navigate.delegate = self
        textField_navigate.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        // preliminary settings for auto completion
        searchCompleter.delegate = self
        
        // apply custom design to each views
        view_navigate.addComponentsV1()
        view_crop.addComponentsV1()
        view_zoom.addComponentsV1()
        view_settings.addComponentsV1()
        view_completion.addComponentsV1()
        view_list.addComponentsV1()
        view_startNavigation.addComponentsV1()
        view_details.addComponentsV1()
        button_cancel.addComponentsV2()
        button_settings.addComponentsV2()
    }
    
    // MARK: IBAction
    
    /**
        Add pin on map with LongPressure
     */
    @IBAction func addPin(_ sender:UILongPressGestureRecognizer) {
        if sender.state == .began {
            _mapManager.addPinOnMap(sender, mapView: mapView) { (location) in
                self.locationList.append(location)
                self.collectionView_list.reloadData()
            }
        }
    }
    
    @IBAction func editNavigation(_ sender:UIButton) {
        tableView_details.setEditing(sender.tag > 0, animated: true)
        sender.tag = -sender.tag
    }
    /**
      Change MapType of current map view:
      - satellite
      - standard
     */
    @IBAction func changeMapType(_ sender:UIButton) {
        if mapView.mapType == .standard {
            mapView.mapType = .hybrid
        } else {
            mapView.mapType = .standard
        }
    }
    
    /**
      Zoom into current map view
      - sender.tag = 0 => Zoom In
      - sender.tag > 0 => Zoom Out
     */
    @IBAction func zoomIntoMapView(_ sender:UIButton) {
        if sender.tag == 0 {
            _mapManager.zoomIntoSelectedMap(mapView, inOrOut: sender.tag)
        } else  {
            _mapManager.zoomIntoSelectedMap(mapView, inOrOut: sender.tag)
        }
    }
    
    /**
     Open QR Code view and load url
     */
    @IBAction func openWazeQRCode(_ sender:UIButton) {
       let urlString = "waze://?ll=\(_mapManager.customers[sender.tag].1.latitude),\(_mapManager.customers[sender.tag].1.longitude)"
        let vc = storyboard?.instantiateViewController(withIdentifier: "view_qrcode") as! QRCodeViewControler
        vc.urlString = urlString
        vc.modalPresentationStyle = .formSheet
        self.present(vc, animated: true, completion: nil)
    }
    
    /**
      Zoom to user position
     */
    @IBAction func zoomToUserPosition(_ sender:UIButton) {
        _mapManager.zoomOnSpecificLocation(mapView, specificLocation: mapView!.userLocation.coordinate)
    }
    
    /**
      Start settings of navigation
     */
    @IBAction func startNavigationSettings(_ sender:UIButton) {
        sender.isHidden = true
        
        view_completion.isHidden = false
        textField_navigate.isHidden = false
        textField_navigate.becomeFirstResponder()
        
        stackView_setNavigation.isHidden = false
        image_searching.image = UIImage(named:"icon_search")
        //TODO: Faire apparaitre les clients
    }
    
    /**
     Once settings are finish we start navigation
     */
    @IBAction func startNavigation(_ sender:UIButton) {
        if !locationList.isEmpty {
            textField_navigate.placeholder = "Ajouter un client au trajet"
            
            view_crop.isHidden = false
            view_list.isHidden = true
            view_completion.isHidden = true
            view_details.isHidden = false
            
            mapView.removeOverlays(mapView.overlays)
            mapView.removeAnnotations(mapView.annotations)
            
            tableView_details.delegate = self
            tableView_details.dataSource = self
            
            sender.setTitle("Terminer le trajet", for: .normal)
            sender.setTitleColor(.red, for: .normal)
            sender.tag = 1
            
            // points list save each points of trip
            var points:[(String,CLLocationCoordinate2D)] = []
            points.append(("user_position", mapView.userLocation.coordinate))
            for location in locationList {
                points.append((location.adress,location.coordinate))
            }
            _mapManager.customers = points
            _mapManager.travelTime = 0
            _mapManager.distancePaths = []
            initGraph(points: points)
            label_distance.text = "\(Int( _mapManager.distancePaths.map({$0}).reduce(0, +))) km"
            label_travelTime.text = "\(_mapManager.travelTime) min"
            locationList.removeAll()
            collectionView_list.reloadData()
        }
    }
    
    /**
     cancel navigation and return to settings
     */
    @IBAction func cancelNavigation(_ sender:UIButton) {
        textField_navigate.placeholder = "Ajouter un client ou une adresse"
        textField_navigate.becomeFirstResponder()
            
        view_crop.isHidden = true
        view_list.isHidden = false
        view_completion.isHidden = false
        view_details.isHidden = true
        
        button_navigation.setTitle("Démarrer le trajet", for: .normal)
        button_navigation.setTitleColor(.black, for: .normal)
        button_navigation.tag = 0
            
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
            
        // points list save each points of trip
        _mapManager.customers = []
        _mapManager.travelTime = 0
        _mapManager.distancePaths = []
            
        label_distance.text = "km"
        label_travelTime.text = "min"
    }
    
    /**
     Remove location from list
     */
    @IBAction func removeLocationFromList(_ sender:UIButton) {
        for annotation in mapView.annotations {
            if annotation is AdressAnnotation {
                let adrAnnotation = annotation as! AdressAnnotation
                if adrAnnotation.id == locationList[sender.tag].id {
                    mapView.removeAnnotation(annotation)
                }
            }
        }
        locationList.remove(at: sender.tag)
        collectionView_list.reloadData()
    }
    
    
    /**
      Show annotations in map view with crop function
     */
    @IBAction func showOverlaysAndAnnotations(_ sender:UIButton) {
        _mapManager.cropMapViewTrip(mapView)
    }
    
    
    private func initGraph(points:[(String,CLLocationCoordinate2D)]) {
        _mapManager.InitGraph(mapView: mapView, tableView: tableView_details, points, label_travelTime, label_arrivalTime)
    }
}

extension ViewController : MKMapViewDelegate {
    
    /**
     user's annotations
     */
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            let identifier = "pin-annotation"
            var annotationImage = UIImage(named: "icon_navigation")!
            annotationImage = annotationImage.resize(newWidth: 35.0)
            return _mapManager.setImageAnnotation(mapView, viewFor: annotation, annotationImage: annotationImage, identifier: identifier)
        } else if annotation is TimeAnnotation {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: (annotation as! TimeAnnotation).id)
            let routeView = Bundle.main.loadNibNamed("TimeAnnotation", owner: self, options: nil)?.first! as! TimeAnnotationView
            routeView.label_time.text = (annotation as! TimeAnnotation).time
            routeView.frame.size.width = 100
            routeView.frame.size.height = 50
            routeView.addComponentsV2()
            annotationView.addSubview(routeView)
            
            return annotationView
        }
        return nil
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(red: 17.0/255.0, green: 147.0/255.0, blue: 255.0/255.0, alpha: 1)
        renderer.lineWidth = 5.0
        
        return renderer
    }
}

extension ViewController : CLLocationManagerDelegate  {
    
}

extension ViewController: MKLocalSearchCompleterDelegate {
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        tableView_completion.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // handle error
    }
}

extension ViewController:UITextFieldDelegate {
    @objc func textFieldDidChange(_ textField: UITextField) {
        view_completion.isHidden = false
        searchCompleter.queryFragment = textField.text!
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        UIView.animate(withDuration: 1) {
            self.searchResults.removeAll()
            self.tableView_completion.reloadData()
        }
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }

    
}


extension ViewController : UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if view_details.isHidden {
            return searchResults.count
        }
        return _mapManager.customers.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        /*
         si indexPath.row == 0 on ne pourra pas supprimer la editer la premiere cell
         (soit la cellule dédié à la position de l'utilisateur) &&
         si le nombre de client est superieur à 2
         */
        return !(indexPath.row == 0) && _mapManager.customers.count > 2
    }
    
    // moving cells
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        }
        return true
    }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        if sourceIndexPath.row != 0 && destinationIndexPath.row != 0 {
            let swp = _mapManager.customers[sourceIndexPath.row]
            _mapManager.customers[sourceIndexPath.row] = _mapManager.customers[destinationIndexPath.row]
            _mapManager.customers[destinationIndexPath.row] = swp
            // 1. on reload la map et la tableview
            _mapManager.distancePaths = []
            _mapManager.InitSelectedGraph(mapView:mapView, tableView:tableView_details, points: _mapManager.customers, label_travelTime, label_arrivalTime)
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.row != 0 {
            let alert = UIAlertController(title: "Attention", message: "Supprimer cette étape ?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Supprimer", style: .destructive, handler: { (_) in
                
                // on supprime un client de la tableview
                self._mapManager.customers.remove(at: indexPath.row)
                
                self._mapManager.InitGraph(mapView: self.mapView, tableView: tableView, self._mapManager.customers, self.label_travelTime, self.label_arrivalTime)
            }))
            alert.addAction(UIAlertAction(title: "Non", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView_details.setEditing(editing && !tableView_details.isEditing, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if view_details.isHidden {
            let cellCompletion = tableView.dequeueReusableCell(withIdentifier: "cell_completion", for: indexPath) as! LocationCompletionTableViewCell
            let searchResult = searchResults[indexPath.row]
            cellCompletion.label_id.text = searchResult.title
            cellCompletion.label_adress.text = searchResult.subtitle
            return cellCompletion
        } else {
            let cellDetails = tableView.dequeueReusableCell(withIdentifier: "cell_details", for: indexPath) as! TripDetailsTableViewCell
            let customer = _mapManager.customers[indexPath.row]
            cellDetails.label_id.text = customer.0
            cellDetails.label_adress.text = "No Adress" //TODO: Adresse à completer
            if customer.0 != "user_position"  {
                cellDetails.label_distance.isHidden = false
                cellDetails.button_waze.isHidden = false
                cellDetails.button_waze.tag = indexPath.row
                cellDetails.label_distance.text = "\(Double(round(10*_mapManager.distancePaths[indexPath.row - 1])/10)) km"
            } else {
                cellDetails.label_id.text = "Ma position"
                cellDetails.image_icon.image = UIImage(named: "icon_navigation")
                cellDetails.label_distance.isHidden = true
                cellDetails.button_waze.isHidden = true
            }
            return cellDetails
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //1. if we are in settings navigation or not
        if view_details.isHidden {
            view_completion.isHidden = true
            tableView.deselectRow(at: indexPath, animated: true)
            
            let completion = searchResults[indexPath.row]
            let searchRequest = MKLocalSearch.Request(completion: completion)
            let search = MKLocalSearch(request: searchRequest)
            search.start { (response, error) in
                if error != nil {
                    return
                }
                
                self._mapManager.didSelectedCompletion(mapView: self.mapView, response: response!, completion: completion)
                let coordinate = response!.mapItems[0].placemark.coordinate
                
                let locationTmp = Location(id: completion.title, adress: completion.title, coordinate: coordinate)
                
                self.locationList.append(locationTmp)
                self.collectionView_list.reloadData()
            }
            
            
            textField_navigate.text = ""
            searchResults.removeAll()
            tableView.reloadData()
            self.view.endEditing(true)
        } else {
            let location = _mapManager.customers[indexPath.row].1
            _mapManager.zoomOnSpecificLocation(mapView, specificLocation: location)
        }
    }
    
}

extension ViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return locationList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell_list", for: indexPath) as! LocationListCollectionViewCell
        cell.label_id.text = locationList[indexPath.row].id
        cell.label_adress.text = locationList[indexPath.row].adress
        cell.image_icon.image = locationList[indexPath.row].image
        cell.button_delete.tag = indexPath.row
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        _mapManager.zoomOnSpecificLocation(mapView, specificLocation: locationList[indexPath.row].coordinate)
    }
    
}
