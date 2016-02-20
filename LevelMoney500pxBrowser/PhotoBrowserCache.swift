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
    
    var cacheFolderURL : NSURL
    
    var urlSession : NSURLSession

    // http://krakendev.io/blog/the-right-way-to-write-a-singleton
    private override init() {
        
        // I dislike having to do these "placeholder" temporary property settings before doing the real thing
        // later on. more info at: http://stackoverflow.com/a/28431379/981049
        urlSession = NSURLSession.sharedSession()
        cacheFolderURL = NSURL(fileURLWithPath: "/tmp")
        
        super.init()
        
        let cachesDirectory = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)
        
        if cachesDirectory.count > 0
        {
            cacheFolderURL = NSURL(fileURLWithPath: cachesDirectory[0])
        } else {
            print("uh oh... there is no cache folder in this sandbox! -- guess we'll use /tmp for now")
        }
        
        urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }
    
    // if I have any time, I would write a hash function
    // to match the behavior that a URL shortner might be using
    func getFilenameFromURL(urlToFetch: NSURL) -> String
    {
        let originalURLString = "\(urlToFetch.path)\(urlToFetch.parameterString)"
        return originalURLString.stringByAddingPercentEncodingWithAllowedCharacters(.URLHostAllowedCharacterSet())!
    }
    
    func performGetPhotoURLFrom500pxServer(forURL urlToFetch: NSURL, intoImageView imageView: LMImageView)
    {
        // our crafty (and simple) cache simply saves the very unique (or UUID-looking) filename 
        // into the caches folder...
        let cacheFilename = getFilenameFromURL(urlToFetch)
        let cachedFilenameURL = cacheFolderURL.URLByAppendingPathComponent(cacheFilename)

        let imageData = NSData.init(contentsOfURL: cachedFilenameURL)
        
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
                
                if weakImageView!.imageURL == urlToFetch
                {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        weakImageView?.image = image
                    })
                }

                do {
                    try data.writeToURL(cachedFilenameURL, options: .AtomicWrite)
                } catch let error as NSError {
                    print("couldn't write data to \(cachedFilenameURL.absoluteString) - \(error.localizedDescription)")
                }
            } else {
                // this is sloppy and I'm sorry but I'm 2 minutes away from submitting this code back to you :-)
                if let mainwindow = UIApplication.sharedApplication().delegate!.window
                {
                    let alert = UIAlertController(title: "Alert", message: "Didn't get a picture back", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.Default, handler: nil))
                    mainwindow!.rootViewController!.presentViewController(alert, animated: true, completion: nil)
                }
            }
        })
        task.resume()
    }
    
    private func doTheActualTransition(withImage: UIImage, intoImageView imageView: LMImageView, withTransition transition: String)
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            imageView.image = withImage
            let animation = CATransition()
            animation.duration = 1.0
            animation.type = kCATransitionPush
            animation.subtype = transition
            animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseOut)
            imageView.layer.addAnimation(animation, forKey: nil)

        })
    }
    
    
    func transitionToThisPhotoURLFrom500pxServer(urlToFetch: NSURL, intoImageView imageView: LMImageView, viaGestureRecognizer gestureRecognizer: UISwipeGestureRecognizer)
    {
        var transition : String
        
        switch gestureRecognizer.direction {
        case UISwipeGestureRecognizerDirection.Left :
            transition = kCATransitionFromRight
        case UISwipeGestureRecognizerDirection.Right :
            transition = kCATransitionFromLeft
        case UISwipeGestureRecognizerDirection.Down :
            transition = kCATransitionFromTop
        case UISwipeGestureRecognizerDirection.Up :
            transition = kCATransitionFromBottom
        default :
            print("a swipe case I wasn't expecting")
            return
        }

        let cacheFilename = getFilenameFromURL(urlToFetch)
        let cacheURL = NSURL(fileURLWithPath: "/tmp/\(cacheFilename)")
        
        let imageData = NSData.init(contentsOfURL: cacheURL)
        
        if let imageData = imageData
        {
            if let image = UIImage(data: imageData)
            {
                doTheActualTransition(image, intoImageView: imageView, withTransition: transition)
                return
            }
        }

        // imageData was either nil (not cached yet) or invalid, so let's go download it
        let request = NSMutableURLRequest(URL: urlToFetch)
        request.HTTPMethod = "GET"
        let task = urlSession.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            // make the image view weak within the block in the case it goes offscreen and/otherwise becomes junk/nil
            weak var weakImageView = imageView
            
            // the data that comes back isn't JSON, but instead it's picture data!
            if let data = data
            {
                if let image = UIImage(data: data)
                {
                    if weakImageView!.imageURL == urlToFetch
                    {
                        self.doTheActualTransition(image, intoImageView: weakImageView!, withTransition: transition)
                    }
                
                    do {
                        try data.writeToURL(cacheURL, options: .AtomicWrite)
                    } catch let error as NSError {
                        print("couldn't write data to \(cacheURL.absoluteString) - \(error.localizedDescription)")
                    }
                }
            }
        })
        task.resume()
    }
}

