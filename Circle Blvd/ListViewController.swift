//
//  ListViewController.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 4/4/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import CoreData
import UIKit

class ListViewController: UITabBarController, CircleViewProtocol {
    
    var session: NSURLSession? {
        didSet {
            println("session set")
        }
    }
    var baseUrl: String? = ""
    var profile: NSDictionary?
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var circle: NSDictionary?
    
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
    }

}

