//
//  LevelMoney500pxBrowserTests.swift
//  LevelMoney500pxBrowserTests
//
//  Created by Michael Dautermann on 2/18/16.
//  Copyright © 2016 Michael Dautermann. All rights reserved.
//

import XCTest
@testable import LevelMoney500pxBrowser

class LevelMoney500pxBrowserTests: XCTestCase {
    
    var viewController: PhotoBrowserViewController!
    
    var expectation : XCTestExpectation?
    
    override func setUp() {
        super.setUp()
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
        viewController = navigationController.topViewController as! PhotoBrowserViewController
        
        UIApplication.shared.keyWindow!.rootViewController = viewController
        
        // Test and Load the View at the Same Time!
        XCTAssertNotNil(navigationController.view)
        XCTAssertNotNil(viewController.view)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func resultTestFinished() -> () {
        DispatchQueue.main.async(execute: { () -> Void in
            self.expectation?.fulfill()
        })
    }
    
    func testForResults() {
        
        let currentPage = viewController.latestPage
        
        expectation = self.expectation(withDescription: "test for results")

        viewController.performGetNextPageFrom500pxServer(resultTestFinished)
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
        }
        
        let updatedPage = viewController.latestPage
        
        XCTAssert(updatedPage == currentPage+1, "should have incremented a page at this point")

        let numberOfResults = viewController.tableView(viewController.tableView, numberOfRowsInSection: 0)
        
        XCTAssert(updatedPage*20 == numberOfResults, "should have \(updatedPage*20) results for \(updatedPage) pages of pictures")
    }
    
    func testSearchBar()
    {
        viewController.searchBar.text = "$@#$#$#$@" // garbage
        viewController.searchBarSearchButtonClicked(viewController.searchBar)
        let numberOfResults = viewController.tableView(viewController.tableView, numberOfRowsInSection: 0)
        
        XCTAssert(numberOfResults == 0, "garbage search bar contents should yield no results")
    }
}
