//
//  AdressAnnotation.swift
//  TripModule
//
//  Created by Gabriel Elfassi on 13/08/2019.
//  Copyright © 2019 Gabriel Elfassi. All rights reserved.
//

import Foundation
import UIKit
import MapKit

final class AdressAnnotation : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var identifier:String?
    
    init(coordinate:CLLocationCoordinate2D, identifier:String?) {
        self.coordinate = coordinate
        self.identifier = identifier
        
        super.init()
    }
    
    public var id:String {
        get {
            return self.identifier!
        }
    }
}


final class TimeAnnotation: NSObject, MKAnnotation {
    
    // MARK: var variables
    var coordinate: CLLocationCoordinate2D
    private var _identifier:String?
    private var _time:String = ""
    
    init(coordinate:CLLocationCoordinate2D, identifier:String?) {
        self.coordinate = coordinate
        self._identifier = identifier
        
        super.init()
    }
    
    public var id:String {
        get {
            return self._identifier!
        }
    }
    
    public var time:String {
        get {
            return self._time
        } set {
            _time = newValue
        }
    }
}
