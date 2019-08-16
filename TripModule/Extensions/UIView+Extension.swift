//
//  UIView+Extension.swift
//  TripModule
//
//  Created by Gabriel Elfassi on 12/08/2019.
//  Copyright © 2019 Gabriel Elfassi. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    /**
      OUTPUT 1:
      - Shadow
      - Corner radius
     */
    public func addComponentsV1() {
        layer.masksToBounds = false
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = 10
        
        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        layer.shouldRasterize = true
        
        layer.cornerRadius = 10
    }
    
    /**
      OUTPUT 2:
      - Corner radius
     */
    public func addComponentsV2() {
        layer.cornerRadius = 10
    }
}
