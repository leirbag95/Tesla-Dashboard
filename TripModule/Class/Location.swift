//
//  Location.swift
//  TripModule
//
//  Created by Gabriel Elfassi on 12/08/2019.
//  Copyright © 2019 Gabriel Elfassi. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class Location {
    //MARK: private variables
    private var _id:String = String()
    private var _adress:String = String()
    private var _image:UIImage = UIImage()
    private var _coordinate:CLLocationCoordinate2D = CLLocationCoordinate2D()
    
    init(id:String, adress:String, image:UIImage = UIImage(named: "icon_location")!, coordinate:CLLocationCoordinate2D) {
        _id = id
        _adress = adress
        _image = image
        _coordinate = coordinate
    }
    
    public var id:String {
        get {
            return _id
        } set {
            _id = newValue
        }
    }
    
    public var adress:String {
        get {
            return _adress
        } set {
            _adress = newValue
        }
    }
    
    public var image:UIImage {
        get {
            return _image
        } set {
            _image = newValue
        }
    }
    
    public var coordinate:CLLocationCoordinate2D {
        get {
            return _coordinate
        } set {
            _coordinate = newValue
        }
    }
}
