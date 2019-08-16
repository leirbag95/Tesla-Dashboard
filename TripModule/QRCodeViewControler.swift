//
//  QRCodeViewControler.swift
//  TripModule
//
//  Created by Gabriel Elfassi on 16/08/2019.
//  Copyright © 2019 Gabriel Elfassi. All rights reserved.
//

import UIKit

class QRCodeViewControler: UIViewController {

    // MARK: IBOutlet
    @IBOutlet weak var image_qrcode:UIImageView!
    @IBOutlet weak var button_waze:UIButton!
    
    //MARK: variable(s)
    public var urlString = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        button_waze.addComponentsV2()
        
        generateQRCode(url : urlString)
    }
    
    
    // MARK: on genere un qrcode
    public func generateQRCode(url:String) {
        // 2
        let data = url.data(using: String.Encoding.ascii)
        // 3
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return }
        // 4
        qrFilter.setValue(data, forKey: "inputMessage")
        // 5
        guard let qrImage = qrFilter.outputImage else { return }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledQrImage = qrImage.transformed(by: transform)
        
        image_qrcode.image = UIImage(ciImage: scaledQrImage)
    }
    
    @IBAction func closeView(_ sender:UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func openWaze(_ sender:UIButton) {
        var link:String = "waze://"
        let url:NSURL = NSURL(string: urlString)!
        
        if UIApplication.shared.canOpenURL(url as URL) {
            
            UIApplication.shared.open(url as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            //UIApplication.shared.openURL()
            UIApplication.shared.isIdleTimerDisabled = true
            
        } else {
            link = "https://itunes.apple.com/fr/app/navigation-waze-trafic-live/id323229106?mt=8"
            UIApplication.shared.open(NSURL(string: link)! as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
            //UIApplication.shared.openURL()
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}

