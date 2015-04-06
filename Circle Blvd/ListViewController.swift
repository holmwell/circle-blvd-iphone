//
//  ListViewController.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 4/4/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import CoreData
import UIKit

class ListViewController: UITabBarController, UITabBarControllerDelegate, CircleViewProtocol {
    
    var session: NSURLSession? {
        didSet {
            println("session set")
        }
    }
    var baseUrl: String? = ""
    var profile: NSDictionary?
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var circle: NSDictionary?
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
    }
    
    override func viewDidLoad() {
        println("view did load")
        // TODO: Call this after the actualTableView (in CircleView) is ready ...
        // TODO: Make sure we're binding to actualTableView properly
        if let controllers = self.viewControllers {
            for controller in controllers {
                if let circleView = controller as? CircleViewProtocol {
                    println("Setting for circle view protocol")
                    circleView.session = self.session
                    circleView.baseUrl = self.baseUrl
                    circleView.profile = self.profile
                    circleView.managedObjectContext = self.managedObjectContext
                    circleView.circle = self.circle
                    
                    if let circle = circle {
                        self.title = circle["name"] as? String
                    }
                }
            }
        }
        
        if let circle = circle {
            if let circleId = circle["id"] as? String {
                let defaults = NSUserDefaults.standardUserDefaults()
                // This returns 0 if the key is not found.
                let selectedTab = defaults.integerForKey(circleId + "-selectedTab")
                self.selectedIndex = selectedTab
            }
        }
    }

    
    // Called when a new tab is selected
    func tabBarController(tabBarController: UITabBarController,
        didSelectViewController viewController: UIViewController) {
            
            if let circle = circle {
                if let circleId = circle["id"] as? String {
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setInteger(self.selectedIndex, forKey: circleId + "-selectedTab")
                    defaults.synchronize()
                }
            }
    }

}

