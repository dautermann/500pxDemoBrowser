//
//  PhotoBrowserViewController.swift
//  LevelMoney500pxBrowser
//
//  Created by Michael Dautermann on 2/18/16.
//  Copyright © 2016 Michael Dautermann. All rights reserved.
//

import UIKit

class PhotoBrowserViewController: UIViewController, URLSessionDelegate, URLSessionTaskDelegate, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet var tableView : UITableView!
    @IBOutlet var categoryButton : UIButton!
    @IBOutlet var categoryPicker : UIPickerView!
    @IBOutlet var searchBar : UISearchBar!
    
    var urlSession : URLSession
    var latestPage : Int = 0
    var totalPages : Int = 0
    
    var pickerDataSource = ["popular", "highest_rated", "upcoming", "editors", "fresh_today", "fresh_yesterday", "fresh_week"]
    
    var photoArray : [NSDictionary]? // I'm not the biggest fan of mixing Foundation types and native Swift types for a demo app, but I'm under time pressure to deliver
    var filteredPhotoArray : [NSDictionary]?
    
    required init?(coder aDecoder: NSCoder) {
        urlSession = URLSession.shared
        super.init(coder: aDecoder)
        urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        urlSession = URLSession.shared
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        urlSession = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: OperationQueue.main)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performGetNextPageFrom500pxServer(nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // we only want to show the navigation bar when we're in the detail view; no need to show it here
    // (we'd rather show the search bar instead)
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if (navigationController?.topViewController != self) {
            navigationController?.isNavigationBarHidden = false
        }
        super.viewWillDisappear(animated)
    }

    // useful optional closure used for fulfilling expectations
    func performGetNextPageFrom500pxServer(_ closure: (() -> ())?)
    {
        // we'd like to get the next page (i.e. the page after the last one we saw)
        let pageWeWant = self.latestPage+1
        let categoryString = categoryButton.title(for: UIControlState())
        let requestURLString = "https://api.500px.com/v1/photos?feature=\(categoryString!)&page=\(pageWeWant)&image_size=600&consumer_key=vW8Ns53y0F57vkbHeDfe3EsYFCatTJ3BrFlhgV3W"
        let request = NSMutableURLRequest(url: URL(string:requestURLString)!)
        
        request.httpMethod = "GET"
        
        let task = urlSession.dataTask(with: request, completionHandler: {data, response, error -> Void in
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String:AnyObject]
                
                if let totalPages = json!["total_pages"] as? Int
                {
                    self.totalPages = totalPages
                }
                
                if let newPhotoArray = json!["photos"] as? [NSDictionary]
                {
                    if let currentPage = json!["current_page"] as? Int
                    {
                        // we already got this page, nothing else to do except call
                        // the optional closure and then return
                        if self.latestPage == currentPage
                        {
                            closure?()
                            return;
                        }
                        self.latestPage = currentPage
                    }

                    if self.photoArray == nil {
                        self.photoArray = newPhotoArray
                    } else {
                        self.photoArray!.append(contentsOf: newPhotoArray)
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        var indexPathArray : [IndexPath] = []
                        let previousPage = self.latestPage - 1
                        for var newRow = previousPage*20; newRow < self.latestPage*20; newRow++
                        {
                            let indexPath = IndexPath(row: newRow, section: 0)
                            indexPathArray.append(indexPath)
                        }
                        
                        self.tableView.beginUpdates()
                        self.tableView.insertRows(at: indexPathArray, with: UITableViewRowAnimation.automatic)
                        self.tableView.endUpdates()
                    })

                    closure?()
                    
                } else {
                    // okay the json object was nil, something went wrong. Maybe the server isn't running?
                    let jsonStr = NSString(data: data!, encoding: String.Encoding.utf8)
                    print("could not parse JSON: \(jsonStr)")
                    let alert = UIAlertController(title: "Alert", message: "Could not Parse Json", preferredStyle: UIAlertControllerStyle.alert)
                    alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
            catch let error as NSError {
                print("perform get from server error \(error.localizedDescription)")
            }
            catch
            {
                // a catch all...
            }
        })
        task.resume()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        if segue.identifier == "ShowDetail" {
            let destinationVC = segue.destination as! PhotoDetailViewController
            
            if let indexPath = self.tableView.indexPathForSelectedRow
            {
                destinationVC.parentVC = self
                destinationVC.photoDict = getPhotoDictAtIndex(indexPath.row)
            }
        }
    }
    
    func getNextPhotoFrom(_ photoDict : NSDictionary?) -> NSDictionary?
    {
        let currentIndex = getIndexOfPhotoDict(photoDict)
        
        if var currentIndex = currentIndex
        {
            if currentIndex >= 0
            {
                currentIndex += 1
                return(getPhotoDictAtIndex(currentIndex))
            }
        }
        return nil
    }
    
    func getPreviousPhotoFrom(_ photoDict: NSDictionary?) -> NSDictionary?
    {
        let currentIndex = getIndexOfPhotoDict(photoDict)
        
        if var currentIndex = currentIndex
        {
            if currentIndex > 0
            {
                currentIndex -= 1
                return(getPhotoDictAtIndex(currentIndex))
            }
        }
        return nil
    }
    
    func getIndexOfPhotoDict(_ photoDict:NSDictionary?) -> Int?
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
        
        return(activePhotoArray!.index(of: photoDict))
    }
    
    func getPhotoDictAtIndex(_ indexNumber:Int) -> NSDictionary?
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
    
    @IBAction func categoryButtonTouched(_ sender: UIButton)
    {
        categoryPicker.isHidden = false;
        categoryPicker.backgroundColor = UIColor.white
        
        // cheap and dirty way of disabling the photo picker
        tableView.isUserInteractionEnabled = false;
        tableView.alpha = 0.3
        tableView.backgroundColor = UIColor.black
    }
    
    // MARK: table view data source & delegate functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let tableCell = tableView.dequeueReusableCell(withIdentifier: "PhotoBrowserTableViewCell", for: indexPath) as! PhotoBrowserTableViewCell
        
        // I'm not too worried about dereferencing here because cellForRowAtIndexPath only gets called
        // with a valid row number thanks to the numberOfRowsInSection function above
        if let photoDict = getPhotoDictAtIndex(indexPath.row)
        {
            if let userDict = photoDict["user"]
            {
                tableCell.userNameLabel.text = userDict["fullname"] as? String

                if let avatarURLString = (userDict as AnyObject).value(forKeyPath: "avatars.large.https") as? String
                {
                    if let photoURL = URL(string: avatarURLString)
                    {
                        tableCell.userThumbnailImageView!.imageURL = photoURL
                        PhotoBrowserCache.sharedInstance.performGetPhotoURLFrom500pxServer(forURL: photoURL, intoImageView: tableCell.userThumbnailImageView!)
                    }
                }
            }

            tableCell.titleLabel.text = photoDict["name"] as? String
            if let photoURLString = photoDict["image_url"] as? String
            {
                if let photoURL = URL(string: photoURLString)
                {
                    tableCell.photoImageView!.imageURL = photoURL
                    PhotoBrowserCache.sharedInstance.performGetPhotoURLFrom500pxServer(forURL: photoURL, intoImageView: tableCell.photoImageView!)
                }
            }
            
            tableCell.selectionStyle = .blue
        }
        return tableCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "ShowDetail", sender: self)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        // I'm only going to do this paging thing if we're not doing a current search filter at the moment
        if filteredPhotoArray == nil
        {
            if let photoArray = self.photoArray
            {
                if indexPath.row >= photoArray.count - 1
                {
                    let pageWeWant = latestPage+1
                    
                    // I probably need to check to see if page 1000 will get returned
                    // from the server when it says there are 1000 total pages
                    //
                    if pageWeWant <= totalPages
                    {
                        performGetNextPageFrom500pxServer(nil)
                    }
                }
            }
        }
    }
    
    // MARK: search bar functionality
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar)
    {
        searchBar.text = ""
        self.filteredPhotoArray = nil
        self.tableView.reloadData()
    }
    
    // need to hook into the clear button of the search bar?
    // http://stackoverflow.com/a/33916306/981049
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.characters.count == 0 {
            perform(#selector(PhotoBrowserViewController.hideKeyboardWithSearchBar(_:)), with:searchBar, afterDelay:0)
        }
    }
    
    func hideKeyboardWithSearchBar(_ searchBar:UISearchBar) {
        searchBar.resignFirstResponder()
        searchBarCancelButtonClicked(searchBar)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        // if the user simply empties out the string, then they are removing the search filter
        if(searchBar.text!.characters.count == 0)
        {
            searchBarCancelButtonClicked(searchBar);
        } else {
            // can't do anything with a nil photoArray
            guard let photoArray = photoArray else {
                return
            }
            let array = NSArray(array: photoArray)
            
            self.filteredPhotoArray = array.filtered(using: NSPredicate(format:"name CONTAINS %@", searchBar.text!)) as? [NSDictionary]
            
            self.tableView.reloadData()
        }
    }
    
    // MARK: picker view functionality
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataSource.count;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataSource[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categoryButton.setTitle(pickerDataSource[row], for: UIControlState())
        filteredPhotoArray = nil
        self.photoArray = nil
        latestPage = 0
        totalPages = 0
        searchBar.text = ""
        self.tableView.reloadData()
        performGetNextPageFrom500pxServer(nil)
        pickerView.isHidden = true
        tableView.isUserInteractionEnabled = true
        tableView.alpha = 1.0
        tableView.backgroundColor = UIColor.clear
    }
}

