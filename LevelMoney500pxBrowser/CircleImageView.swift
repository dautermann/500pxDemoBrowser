//
//  CircleImageView.swift
//  LevelMoney500pxBrowser
//
//  Created by Michael Dautermann on 2/18/16.
//  Copyright © 2016 Michael Dautermann. All rights reserved.
//

import UIKit

class LMImageView: UIImageView {
    // keep track of this image view's URL, super useful in case we want 
    // to cancel setting (or assigning) an image that doesn't match the view's current URL
    var imageURL : NSURL?
}

class CircleImageView: LMImageView {

    // handy code found at http://stackoverflow.com/questions/7399343/making-a-uiimage-to-a-circle-form
    override var image: UIImage? {
        didSet {
            if let image = image {
                let newImage = image.copy() as! UIImage
                let cornerRadius = image.size.height/2
                UIGraphicsBeginImageContextWithOptions(image.size, false, 1.0)
                let bounds = CGRect(origin: CGPointZero, size: image.size)
                UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).addClip()
                newImage.drawInRect(bounds)
                let finalImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                super.image = finalImage
            }
        }
    }
}
