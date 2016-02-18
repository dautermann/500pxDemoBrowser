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
            }
        }
    }
    
}
