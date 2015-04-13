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
    
    @IBAction func longPressAction(sender: UILongPressGestureRecognizer) {
        
        if (sender.state == UIGestureRecognizerState.Began) {
            if let tableView = actualTableView {
                let point = sender.locationInView(tableView)
                let indexPath = tableView.indexPathForRowAtPoint(point)
                
                if let path = indexPath {
                    if let task = tableView.fetchedResultsController.objectAtIndexPath(path) as? Task {
                        task.status = "done"
                        saveTask(task)
                    }
                }
            }
        }
    }
    
    func valueOrEmptyString(optional: NSString?) -> NSString {
        if (optional != nil) {
            return optional!
        }
        else {
            return ""
        }
    }
    
    func didSaveTask() {
        didSaveTask("")
    }
    
    func didSaveTask(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if (!message.isEmpty) {
                let alert = UIAlertController(title: "Could not save", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                let alertAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in }
                
                alert.addAction(alertAction)
                self.presentViewController(alert, animated: false, completion: { () -> Void in })
            }
        }
    }
    
    // TODO: Move this to Task
    func saveTask(task: Task) {
        func getSaveRequest(task: Task) -> NSURLRequest {
            
            var request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl! + "/data/story")!)
            
            request.HTTPMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            var parameters = NSMutableDictionary()
            parameters["id"] = task.id
            parameters["summary"] = task.summary
            parameters["description"] = valueOrEmptyString(task.longDescription)
            parameters["owner"] = valueOrEmptyString(task.owner)
            parameters["status"] = valueOrEmptyString(task.status)
            parameters["projectId"] = task.circleId
            
            // pass dictionary to nsdata object and set it as request body
            var err: NSError?
            request.HTTPBody = NSJSONSerialization.dataWithJSONObject(parameters, options: nil, error: &err)
            
            return request
        }
        
        
        if let session = session {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            let request = getSaveRequest(task)
            let dataTask = session.dataTaskWithRequest(request, completionHandler: {
                (data: NSData!, response:NSURLResponse!, error: NSError!) -> Void in
                
                if let httpResponse = response as? NSHTTPURLResponse {
                    if (httpResponse.statusCode == 200) {
                        self.didSaveTask()
                    }
                    else {
                        // TODO: Show error (invalid login)
                        if (httpResponse.statusCode >= 500) {
                            self.didSaveTask("Sorry, our server has failed us. Maybe it is busy. Please try again.")
                        }
                        else if (httpResponse.statusCode >= 400) {
                            self.didSaveTask("Sorry, please sign in again.")
                        }
                        else {
                            println("Received an unexpected result from the server.")
                            self.didSaveTask("Sorry, we don't know what is happening. It's our fault, but if you keep seeing this, you might want to upgrade your app.")
                        }
                    }
                }
                else {
                    self.didSaveTask("Sorry, we could not connect to the internet.")
                }
            })
            dataTask.resume()
        }
    }

    
    
    
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

    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)

        // Disconnect Socket IO from the server. This isn't exactly good
        // object oriented code. Feel free to fix it.
        if let tableView = actualTableView {
            if let socket = tableView.socket {
                socket.disconnect(fast: false)
            }
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

