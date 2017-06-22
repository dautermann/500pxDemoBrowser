//
//  PhotoBrowserCache.swift
//  LevelMoney500pxBrowser
//
//  Created by Michael Dautermann on 2/18/16.
//  Copyright © 2016 Michael Dautermann. All rights reserved.
//

import Foundation
import UIKit

class PhotoBrowserCache: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    
    static let sharedInstance = PhotoBrowserCache()
    
    var cacheFolderURL : URL
    
    var urlSession : URLSession

    // http://krakendev.io/blog/the-right-way-to-write-a-singleton
    fileprivate override init() {
        
        // I dislike having to do these "placeholder" temporary property settings before doing the real thing
        // later on. more info at: http://stackoverflow.com/a/28431379/981049
        urlSession = URLSession.shared
        cacheFolderURL = URL(fileURLWithPath: "/tmp")
        
        super.init()
        
        let cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        
        if cachesDirectory.count > 0
        {
            cacheFolderURL = URL(fileURLWithPath: cachesDirectory[0])
        } else {
            print("uh oh... there is no cache folder in this sandbox! -- guess we'll use /tmp for now")
        }
        
        urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    // if I have any time, I would write a hash function
    // to match the behavior that a URL shortner might be using
    func getFilenameFromURL(_ urlToFetch: URL) -> String
    {
        let originalURLString = "\(urlToFetch.path)\(urlToFetch.path)"
        return originalURLString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
    
    func performGetPhotoURLFrom500pxServer(forURL urlToFetch: URL, intoImageView imageView: LMImageView)
    {
        // our crafty (and simple) cache simply saves the very unique (or UUID-looking) filename 
        // into the caches folder...
        let cacheFilename = getFilenameFromURL(urlToFetch)
        let cachedFilenameURL = cacheFolderURL.appendingPathComponent(cacheFilename)

        let imageData = try? Data.init(contentsOf: cachedFilenameURL)
        
        if let imageData = imageData
        {
            let image = UIImage(data: imageData)
            
            DispatchQueue.main.async(execute: { () -> Void in
                imageView.image = image
                imageView.isUserInteractionEnabled = false
            })
        }

        var request = URLRequest(url: urlToFetch)
        
        request.httpMethod = "GET"
        
        let task = urlSession.dataTask(with: request, completionHandler: {data, response, error -> Void in

            // make the image view weak within the block in the case it goes offscreen and/otherwise becomes junk/nil
            weak var weakImageView = imageView
            
            // the data that comes back isn't JSON, but instead it's picture data!
            if let data = data
            {
                let image = UIImage(data: data)
                
                if weakImageView!.imageURL == urlToFetch
                {
                    DispatchQueue.main.async(execute: { () -> Void in
                        weakImageView?.image = image
                    })
                }

                do {
                    try data.write(to: cachedFilenameURL, options: .atomicWrite)
                } catch let error as NSError {
                    print("couldn't write data to \(cachedFilenameURL.absoluteString) - \(error.localizedDescription)")
                }
            } else {
                // this is sloppy and I'm sorry but I'm 2 minutes away from submitting this code back to you :-)
                if let mainwindow = UIApplication.shared.delegate!.window
                {
                    let alert = UIAlertController(title: "Alert", message: "Didn't get a picture back", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                    mainwindow!.rootViewController!.present(alert, animated: true, completion: nil)
                }
            }
        })
        task.resume()
    }
    
    fileprivate func doTheActualTransition(_ withImage: UIImage, intoImageView imageView: LMImageView, withTransition transition: String)
    {
        DispatchQueue.main.async(execute: { () -> Void in
            
            imageView.image = withImage
            let animation = CATransition()
            animation.duration = 1.0
            animation.type = kCATransitionPush
            animation.subtype = transition
            animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseOut)
            imageView.layer.add(animation, forKey: nil)

        })
    }
    
    // totally ironically (and I don't know if anyone is reading this, because I didn't include this comment
    // in the repo I sent back to the interviewer), the below function is a modernized Swift version of a function
    // I delivered to Capital One (the company that currently owns LevelMoney) in a previous coding assignment
    // found here -> https://github.com/dautermann/CapitalOneImageSwipeTest/blob/master/SlideViewTest/ViewController.m
    func transitionToThisPhotoURLFrom500pxServer(_ urlToFetch: URL, intoImageView imageView: LMImageView, viaGestureRecognizer gestureRecognizer: UISwipeGestureRecognizer)
    {
        var transition : String
        
        switch gestureRecognizer.direction {
        case UISwipeGestureRecognizerDirection.left :
            transition = kCATransitionFromRight
        case UISwipeGestureRecognizerDirection.right :
            transition = kCATransitionFromLeft
        case UISwipeGestureRecognizerDirection.down :
            transition = kCATransitionFromTop
        case UISwipeGestureRecognizerDirection.up :
            transition = kCATransitionFromBottom
        default :
            print("a swipe case I wasn't expecting")
            return
        }

        let cacheFilename = getFilenameFromURL(urlToFetch)
        let cacheURL = URL(fileURLWithPath: "/tmp/\(cacheFilename)")
        
        let imageData = try? Data.init(contentsOf: cacheURL)
        
        if let imageData = imageData
        {
            if let image = UIImage(data: imageData)
            {
                doTheActualTransition(image, intoImageView: imageView, withTransition: transition)
                return
            }
        }

        // imageData was either nil (not cached yet) or invalid, so let's go download it
        var request = URLRequest(url: urlToFetch)
        request.httpMethod = "GET"
        let task = urlSession.dataTask(with: request, completionHandler: {data, response, error -> Void in
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
                        try data.write(to: cacheURL, options: .atomicWrite)
                    } catch let error as NSError {
                        print("couldn't write data to \(cacheURL.absoluteString) - \(error.localizedDescription)")
                    }
                }
            }
        })
        task.resume()
    }
}

