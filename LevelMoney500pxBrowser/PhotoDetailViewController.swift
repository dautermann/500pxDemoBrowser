//
//  PhotoDetailViewController.swift
//  LevelMoney500pxBrowser
//
//  Created by Michael Dautermann on 2/18/16.
//  Copyright © 2016 Michael Dautermann. All rights reserved.
//

import UIKit

class PhotoDetailViewController: UIViewController {
    
    @IBOutlet var imageView : LMImageView!
    
    var parentVC : PhotoBrowserViewController?
    var photoDict : NSDictionary?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
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
            if let photoURL = URL(string: photoURLString)
            {
                imageView.imageURL = photoURL
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
    
    func doTransition(_ gestureRecognizer: UISwipeGestureRecognizer)
    {
        guard let photoDict = photoDict else {
            return
        }

        if let photoURLString = photoDict["image_url"] as? String
        {
            if let photoURL = URL(string: photoURLString)
            {
                imageView.imageURL = photoURL
                PhotoBrowserCache.sharedInstance.transitionToThisPhotoURLFrom500pxServer(photoURL, intoImageView: imageView!, viaGestureRecognizer: gestureRecognizer)
                setPhotoTitle()
            }
        }
    }
    
    @IBAction func swipeRight(_ sender: UISwipeGestureRecognizer)
    {
        // go to previous picture, if available
        let newPhotoDict = parentVC?.getPreviousPhotoFrom(photoDict)
        if newPhotoDict != photoDict
        {
            photoDict = newPhotoDict
            doTransition(sender)
        }
    }

    @IBAction func swipeLeft(_ sender: UISwipeGestureRecognizer)
    {
        // go to next picture, if available
        let newPhotoDict = parentVC?.getNextPhotoFrom(photoDict)
        if newPhotoDict != photoDict
        {
            photoDict = newPhotoDict
            doTransition(sender)
        }
    }

}
