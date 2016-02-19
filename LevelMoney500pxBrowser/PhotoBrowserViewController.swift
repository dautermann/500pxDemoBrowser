//
//  PhotoBrowserViewController.swift
//  LevelMoney500pxBrowser
//
//  Created by Michael Dautermann on 2/18/16.
//  Copyright © 2016 Michael Dautermann. All rights reserved.
//

import UIKit

class PhotoBrowserViewController: UIViewController, NSURLSessionDelegate, NSURLSessionTaskDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    @IBOutlet var tableView : UITableView!
    @IBOutlet var categoryButton : UIButton!
    @IBOutlet var searchBar : UISearchBar!
    
    var urlSession : NSURLSession
    
    var photoArray : [NSDictionary]? // I'm not the biggest fan of mixing Foundation types and native Swift types for a demo app, but I'm under time pressure to deliver
    var filteredPhotoArray : [NSDictionary]?
    
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

    // we only want to show the navigation bar when we're in the detail view; no need to show it here
    // (we'd rather show the search bar instead)
    override func viewWillAppear(animated: Bool) {
        navigationController?.navigationBarHidden = true
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(animated: Bool) {
        if (navigationController?.topViewController != self) {
            navigationController?.navigationBarHidden = false
        }
        super.viewWillDisappear(animated)
    }

    func performGetFrom500pxServer(forPage pageNumber :Int)
    {
        let requestURLString = "https://api.500px.com/v1/photos?feature=popular&page=\(pageNumber)&image_size=600&consumer_key=L5JIFnakAfeIGbjDwrVdvEzG3N2HisdJL9wS0apV"
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
                destinationVC.parentVC = self
                destinationVC.photoDict = photoArray![indexPath.row]
            }
        }
    }
    
    func getNextPhotoFrom(photoDict : NSDictionary?) -> NSDictionary?
    {
        let currentIndex = getIndexOfPhotoDict(photoDict)
        
        if var currentIndex = currentIndex
        {
            if currentIndex > 0
            {
                currentIndex++
                return(getPhotoDictAtIndex(currentIndex))
            }
        }
        return nil
    }
    
    func getPreviousPhotoFrom(photoDict: NSDictionary?) -> NSDictionary?
    {
        let currentIndex = getIndexOfPhotoDict(photoDict)
        
        if var currentIndex = currentIndex
        {
            if currentIndex > 0
            {
                currentIndex--
                return(getPhotoDictAtIndex(currentIndex))
            }
        }
        return nil
    }
    
    func getIndexOfPhotoDict(photoDict:NSDictionary?) -> Int?
    {
        guard let photoDict = photoDict else {
            return -1
        }
        
        var activePhotoArray = filteredPhotoArray
        
        if activePhotoArray == nil
        {
            activePhotoArray = self.photoArray
            
            if activePhotoArray == nil
            {
                // no active search filter nor any photos currently visible
                return -1
            }
        }
        
        return(activePhotoArray!.indexOf(photoDict))
    }
    
    func getPhotoDictAtIndex(indexNumber:Int) -> NSDictionary?
    {
        var activePhotoArray = filteredPhotoArray
        
        if activePhotoArray == nil
        {
            activePhotoArray = self.photoArray
            
            if activePhotoArray == nil
            {
                // no active search filter nor any photos currently visible
                return nil
            }
        }
        
        if indexNumber >= activePhotoArray!.count
        {
            return nil
        }
        
        return(activePhotoArray![indexNumber])
    }
    
    // MARK: table view data source & delegate functions
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // if we're filtering (searching) on anything, return the result count
        if let filteredPhotoArray = self.filteredPhotoArray
        {
            return filteredPhotoArray.count
        }
        
        if let photoArray = self.photoArray
        {
            return photoArray.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let tableCell = tableView.dequeueReusableCellWithIdentifier("PhotoBrowserTableViewCell", forIndexPath: indexPath) as! PhotoBrowserTableViewCell
        
        // I'm not too worried about dereferencing here because cellForRowAtIndexPath only gets called
        // with a valid row number thanks to the numberOfRowsInSection function above
        if let photoDict = getPhotoDictAtIndex(indexPath.row)
        {
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
        }
        return tableCell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.performSegueWithIdentifier("ShowDetail", sender: self)
    }
    
    // MARK: search bar functionality
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar)
    {
        self.filteredPhotoArray = nil
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar)
    {
        print("search for titles that contain \(searchBar.text)")
        
        // if the user simply empties out the string, then they are removing the search filter
        if(searchBar.text!.characters.count == 0)
        {
            searchBarCancelButtonClicked(searchBar);
        } else {
            let array = NSArray(array: photoArray!)
            
            self.filteredPhotoArray = array.filteredArrayUsingPredicate(NSPredicate(format:"name CONTAINS %@", searchBar.text!)) as? [NSDictionary]
            
            print("filteredArray has \(self.filteredPhotoArray?.count)")
            self.tableView.reloadData()
        }
    }
}

