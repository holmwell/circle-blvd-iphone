//
//  MasterViewController.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 3/30/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import UIKit
import CoreData
import Foundation
import Argo

class MasterViewController: UIViewController, UITabBarDelegate, CircleViewProtocol {

    var session: NSURLSession?
    var baseUrl: String?

    var profile: NSDictionary?
    var managedObjectContext: NSManagedObjectContext?
    var circle: NSDictionary? 
    
    @IBOutlet weak var titleItem: UINavigationItem!

    @IBOutlet weak var myTasksItem: UITabBarItem!
    
    @IBOutlet weak var allTasksItem: UITabBarItem!
    
    @IBOutlet weak var tabBar: UITabBar!
    
    @IBAction func refreshData(sender: UIBarButtonItem) {
        if let tableView = actualTableView {
            tableView.reloadData()
        }
    }
    
    @IBAction func myTasksAction(sender: UIBarButtonItem) {
        if let tableView = actualTableView {
            tableView.viewFilter = CircleViewFilter.MyTasks
            updateTitlePrompt()
        }
    }
    
    @IBAction func allTasksAction(sender: UIBarButtonItem) {
        if let tableView = actualTableView {
            tableView.viewFilter = CircleViewFilter.AllTasks
            updateTitlePrompt()
        }
    }

    func updateTitlePrompt() {
//        if let tableView = actualTableView {
//            switch (tableView.viewFilter) {
//            case .AllTasks:
//                titleItem.prompt = nil
//                break
//            case .MyTasks:
//                titleItem.prompt = "My tasks"
//                break
//            }
//        }
    }
    
    
    @IBOutlet weak var actualTableView: CircleView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tableView = actualTableView {
            // TODO: Check to make sure these values are set
            actualTableView.session = session
            actualTableView.baseUrl = baseUrl
            actualTableView.profile = profile
            actualTableView.managedObjectContext = managedObjectContext
            actualTableView.circle = circle
            
            // TODO: do we need to actualTableView.reloadData()?
            
            if let circle = circle {
                if let circleName = circle["name"] as String? {
                    self.title = circleName
                }
            }
            
            if let tabBar = tabBar {
                tabBar.delegate = self
                
                switch tableView.viewFilter {
                case .AllTasks:
                    tabBar.selectedItem = allTasksItem
                    break
                case .MyTasks:
                    tabBar.selectedItem = myTasksItem
                    break
                }
            }
            
            updateTitlePrompt()
        }
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.actualTableView.indexPathForSelectedRow() {
                let object = self.actualTableView.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject
                let destination = segue.destinationViewController as DetailViewController
                destination.detailItem = object
                destination.baseUrl = self.baseUrl
                destination.session = self.session
                destination.profile = self.profile
            }
        }
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem!) {
        if let filter = CircleViewFilter(rawValue: item.tag) {
            if let tableView = actualTableView {
                tableView.viewFilter = filter
                updateTitlePrompt()
            }
        }
    }
}

