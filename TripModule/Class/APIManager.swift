//
//  APIManager.swift
//  TripModule
//
//  Created by Gabriel Elfassi on 19/08/2019.
//  Copyright © 2019 Gabriel Elfassi. All rights reserved.
//

import UIKit
import Alamofire
import MapKit

class APIManager {
    /**
     You can start using this key to make web service requests. Simply pass your key in the URL when making a web request.
     ex: https://developer.nrel.gov/api/alt-fuel-stations/v1.json?limit=10&latitude=48.889375&longitude=2.280486&api_key=UowR7aYi8t14opqu5wsa1PxY9ZU3ybgJb4pPTGL2&format=JSON
     */
    let API_KEY = "your_api_key"
    
    
    public func getNearestFuelStation(mapView:MKMapView, currentLocation:CLLocationCoordinate2D) {
        let url = "https://developer.nrel.gov/api/alt-fuel-stations/v1.json?api_key=\(API_KEY)&limit=100"
        Alamofire.request(url).responseJSON {
            response in
            switch response.result {
            case .success:
                if let json = response.result.value {
                    
                    let stations = (json as! NSDictionary)["fuel_stations"] as! [NSDictionary]
                    for station in stations {
                        let latitude = station["latitude"]
                        let longitude = station["longitude"]
                        let coordinate = CLLocationCoordinate2D(latitude: latitude as! Double, longitude: longitude as! Double)
                        let annotation = StationAnnotation(coordinate:coordinate , identifier: "station \(station["id"] as! Int)")
                        
                        mapView.addAnnotation(annotation)
                    }
                    mapView.showAnnotations(mapView.annotations, animated: true)
                }
                print("success")
            case .failure(let error):
                debugPrint(error)
            }
            
        }
    }
    
}
