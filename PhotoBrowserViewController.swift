//
//  PhotoBrowserViewController.swift
//  LevelMoney500pxBrowser
//
//  Created by Michael Dautermann on 2/18/16.
//  Copyright © 2016 Michael Dautermann. All rights reserved.
//

import UIKit

class PhotoBrowserViewController: UIViewController, NSURLSessionDelegate, NSURLSessionTaskDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView : UITableView!
    
    var urlSession : NSURLSession
    
    var photoArray : [NSDictionary]? // I'm not the biggest fan of mixing Foundation types and native Swift types for a demo app, but I'm under time pressure to deliver
    
    required init?(coder aDecoder: NSCoder) {
        urlSession = NSURLSession.sharedSession()

        super.init(coder: aDecoder)
        
        urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        performGetFrom500pxServer(forPage: 1)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func performGetFrom500pxServer(forPage pageNumber :Int)
    {
        let requestURLString = "https://api.500px.com/v1/photos?feature=popular&page=\(pageNumber)&consumer_key=INSERT_CONSUMER_KEY_HERE"
        let request = NSMutableURLRequest(URL: NSURL(string:requestURLString)!)
        
        request.HTTPMethod = "GET"
        
        let task = urlSession.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as? [String:AnyObject]
                
                if let newPhotoArray = json!["photos"] as? [NSDictionary]
                {
                    print("photoArray is \(newPhotoArray)")
                    
                    if self.photoArray == nil {
                        self.photoArray = newPhotoArray
                    } else {
                        self.photoArray!.appendContentsOf(newPhotoArray)
                    }
                    
                    print("photo array has \(self.photoArray!.count) entries")
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                    })
                } else {
                    // okay the json object was nil, something went wrong. Maybe the server isn't running?
                    let jsonStr = NSString(data: data!, encoding: NSUTF8StringEncoding)
                    print("could not parse JSON: \(jsonStr)")
                }
            }
            catch let error as NSError {
                print("perform get from server error \(error.localizedDescription)")
            }
            catch
            {
                
            }
        })
        task.resume()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if segue.identifier == "ShowDetail" {
            let destinationVC = segue.destinationViewController as! PhotoDetailViewController
            
            if let indexPath = self.tableView.indexPathForSelectedRow
            {
                destinationVC.photoDict = photoArray![indexPath.row]
            }
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.photoArray == nil
        {
            return 0
        } else {
            return photoArray!.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let tableCell = tableView.dequeueReusableCellWithIdentifier("PhotoBrowserTableViewCell", forIndexPath: indexPath) as! PhotoBrowserTableViewCell
        
        // I'm not too worried about dereferencing here because cellForRowAtIndexPath only gets called
        // with a valid row number thanks to the numberOfRowsInSection function above
        let photoDict = self.photoArray![indexPath.row]
        
        if let userDict = photoDict["user"]
        {
            tableCell.userNameLabel.text = userDict["fullname"] as? String

            if let avatarURLString = userDict.valueForKeyPath("avatars.large.https") as? String
            {
                if let photoURL = NSURL(string: avatarURLString)
                {
                    PhotoBrowserCache.sharedInstance.performGetPhotoURLFrom500pxServer(forURL: photoURL, intoImageView: tableCell.userThumbnailImageView!)
                }
            }
        }

        tableCell.titleLabel.text = photoDict["name"] as? String
        if let photoURLString = photoDict["image_url"] as? String
        {
            if let photoURL = NSURL(string: photoURLString)
            {
                PhotoBrowserCache.sharedInstance.performGetPhotoURLFrom500pxServer(forURL: photoURL, intoImageView: tableCell.photoImageView!)
            }
        }
        
        tableCell.selectionStyle = .Blue
        
        return tableCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("ShowDetail", sender: self)
    }
}

