//
//  DistanceCalculator.swift
//  IsoSales-PreProd
//
//  Created by Gabriel Elfassi on 25/06/2018.
//  Copyright © 2018 Isotoner. All rights reserved.
//

import Foundation
import CoreLocation

class DistanceCalculator {
    
    public func distanceCalculator(p1:CLLocationCoordinate2D, p2:CLLocationCoordinate2D) -> Double {
        
        let lat2 = p2.latitude
        
        let lat1 = p1.latitude
        
        let rayon = 6371.0; // Radius of the earth in km
        
        let dLat = deg2rad(deg: p2.latitude-p1.latitude);  // deg2rad below
        
        let dLon = deg2rad(deg: p2.longitude-p1.longitude);
        
        let a = sin(dLat/2) * sin(dLat/2) + cos(deg2rad(deg: lat1)) * cos(deg2rad(deg: lat2)) * sin(dLon/2) * sin(dLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a));
        
        let distance = rayon * c; // Distance in km
        
        return distance
    }
    
    public func deg2rad(deg:Double) -> Double {
        return deg * (Double.pi/180)
    }
}
