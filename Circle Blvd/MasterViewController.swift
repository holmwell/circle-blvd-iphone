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
    
    @IBAction func addTask(sender: UIBarButtonItem) {
        performSegueWithIdentifier("toAddTask", sender: self)
    }
    
    @IBAction func unwindToMaster(segue: UIStoryboardSegue) {
        // Unwind destination ...
    }

    @IBAction func longPress(sender: UILongPressGestureRecognizer) {
        if let cell = sender.view as? UITableViewCell {
            println("LONG PRESS")
        }
    }
    
    @IBAction func myTasksAction(sender: UIBarButtonItem) {
        if let tableView = actualTableView {
            tableView.viewFilter = CircleViewFilter.MyTasks
            updateTitlePrompt()
            updateNavigationButtons()
        }
    }
    
    @IBAction func allTasksAction(sender: UIBarButtonItem) {
        if let tableView = actualTableView {
            tableView.viewFilter = CircleViewFilter.AllTasks
            updateTitlePrompt()
            updateNavigationButtons()
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
            //tableView.editing = true
            // tableView.setEditing(true, animated: true)
            
            
            if let circle = circle {
                if let circleName = circle["name"] as? String? {
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
            updateNavigationButtons()
        }
    }

    func updateNavigationButtons() {
        // Do any additional setup after loading the view, typically from a nib.
        let addButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "addTask:")
        
        let editButton = UIBarButtonItem(title: "Order", style: UIBarButtonItemStyle.Plain, target: self, action: "toggleMove:")
        editButton.tag = 0
        
        var buttonItems = [UIBarButtonItem]()
        buttonItems.append(addButton)
        if let tableView = actualTableView {
            if tableView.viewFilter == CircleViewFilter.AllTasks {
                buttonItems.append(editButton)
            }
        }
        //buttonItems.append(nil)
        self.navigationItem.setRightBarButtonItems(buttonItems, animated: true)
    }
    
    func toggleMove(sender: UIBarButtonItem) {
        if sender.tag == 0 {
            sender.title = "Done"
            sender.tag = 1
            actualTableView?.setEditing(true, animated: true)
        }
        else {
            sender.title = "Order"
            sender.tag = 0
            actualTableView?.setEditing(false, animated: true)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.actualTableView.indexPathForSelectedRow() {
                let object = self.actualTableView.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
                let destination = segue.destinationViewController as! DetailViewController
                destination.detailItem = object
                destination.baseUrl = self.baseUrl
                destination.session = self.session
                destination.profile = self.profile
            }
        }
        else if segue.identifier == "toAddTask" {
            let destination = segue.destinationViewController as! AddTaskController
            destination.circle = self.circle
            destination.baseUrl = self.baseUrl
            destination.session = self.session
            destination.profile = self.profile
        }
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem!) {
        if let filter = CircleViewFilter(rawValue: item.tag) {
            if let tableView = actualTableView {
                tableView.viewFilter = filter
                updateTitlePrompt()
                updateNavigationButtons()
            }
        }
    }
}

