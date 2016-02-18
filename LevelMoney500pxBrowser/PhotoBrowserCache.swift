//
//  PhotoBrowserCache.swift
//  LevelMoney500pxBrowser
//
//  Created by Michael Dautermann on 2/18/16.
//  Copyright © 2016 Michael Dautermann. All rights reserved.
//

import Foundation
import UIKit

class PhotoBrowserCache: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate {
    
    static let sharedInstance = PhotoBrowserCache()
    
    var urlSession : NSURLSession

    private override init() {
        
        // I dislike having to do these "placeholder" temporary property settings before doing the real thing
        // later on. more info at: http://stackoverflow.com/a/28431379/981049
        urlSession = NSURLSession.sharedSession()
        
        super.init()
        
        urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }
    
    // if I have any time, I would write a hash function
    // to match the behavior that a URL shortner might be using
    func getFilenameFromURL(urlToFetch: NSURL) -> String
    {
        let originalURLString = "\(urlToFetch.path)\(urlToFetch.parameterString)"
        return originalURLString.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
    }
    
    func performGetPhotoURLFrom500pxServer(forURL urlToFetch: NSURL, intoImageView imageView: UIImageView)
    {
        // our crafty (and simple) cache simply saves the very unique (or UUID-looking) filename 
        // into the caches folder...
        let cacheFilename = getFilenameFromURL(urlToFetch)
        let cacheURL = NSURL(fileURLWithPath: "/tmp/\(cacheFilename)")

        let imageData = NSData.init(contentsOfURL: cacheURL)
        
        if let imageData = imageData
        {
            let image = UIImage(data: imageData)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                imageView.image = image
                imageView.userInteractionEnabled = false
            })
        }

        let request = NSMutableURLRequest(URL: urlToFetch)
        
        request.HTTPMethod = "GET"
        
        let task = urlSession.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            // make the image view weak within the block in the case it goes offscreen and/otherwise becomes junk/nil
            weak var weakImageView = imageView
            
            // the data that comes back isn't JSON, but instead it's picture data!
            if let data = data
            {
                let image = UIImage(data: data)
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    weakImageView?.image = image
                })

                do {
                    try data.writeToURL(cacheURL, options: .AtomicWrite)
                } catch let error as NSError {
                    print("couldn't write data to \(cacheURL.absoluteString) - \(error.localizedDescription)")
                }
            }
        })
        task.resume()
    }
}

extension UIImage
{
    func roundImage() -> UIImage
    {
        let newImage = self.copy() as! UIImage
        let cornerRadius = self.size.height/2
        UIGraphicsBeginImageContextWithOptions(self.size, false, 1.0)
        let bounds = CGRect(origin: CGPointZero, size: self.size)
        UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).addClip()
        newImage.drawInRect(bounds)
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return finalImage
    }
}