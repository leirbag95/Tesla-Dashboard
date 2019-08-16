//
//  UIImage+Extension.swift
//  TripModule
//
//  Created by Gabriel Elfassi on 12/08/2019.
//  Copyright © 2019 Gabriel Elfassi. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func resize(newWidth: CGFloat) -> UIImage {
        let scale = newWidth / size.width
        let newHeight = size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        draw(in: CGRect(x:0,y: 0, width: newWidth, height :newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
}
