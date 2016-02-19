//
//  PhotoDetailViewController.swift
//  LevelMoney500pxBrowser
//
//  Created by Michael Dautermann on 2/18/16.
//  Copyright © 2016 Michael Dautermann. All rights reserved.
//

import UIKit

class PhotoDetailViewController: UIViewController {
    
    @IBOutlet var imageView : UIImageView!
    
    var parentVC : PhotoBrowserViewController?
    var photoDict : NSDictionary?
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadCurrentPhoto()
    }
    
    func loadCurrentPhoto()
    {
        guard let photoDict = photoDict else {
            return
        }
        if let photoURLString = photoDict["image_url"] as? String
        {
            if let photoURL = NSURL(string: photoURLString)
            {
                PhotoBrowserCache.sharedInstance.performGetPhotoURLFrom500pxServer(forURL: photoURL, intoImageView: imageView!)
                setPhotoTitle()
            }
        }
    }
    
    func setPhotoTitle()
    {
        if let title = photoDict!["name"] as? String
        {
            self.navigationItem.title = title
        }
    }
    
    func doTransition(gestureRecognizer: UISwipeGestureRecognizer)
    {
        guard let photoDict = photoDict else {
            return
        }

        if let photoURLString = photoDict["image_url"] as? String
        {
            if let photoURL = NSURL(string: photoURLString)
            {
                PhotoBrowserCache.sharedInstance.transitionToThisPhotoURLFrom500pxServer(photoURL, intoImageView: imageView!, viaGestureRecognizer: gestureRecognizer)
                setPhotoTitle()
            }
        }
    }
    
    @IBAction func swipeRight(sender: UISwipeGestureRecognizer)
    {
        // go to previous picture, if available
        photoDict = parentVC?.getPreviousPhotoFrom(photoDict)
        doTransition(sender)
    }

    @IBAction func swipeLeft(sender: UISwipeGestureRecognizer)
    {
        // go to next picture, if available
        photoDict = parentVC?.getNextPhotoFrom(photoDict)
        doTransition(sender)
    }

}
