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

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var managedObjectContext: NSManagedObjectContext? = nil
    var session: NSURLSession? = nil
    var baseUrl: String = ""
    var circle: NSDictionary?

    @IBOutlet var taskTableView: UITableView!
    @IBOutlet weak var myLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
//        self.navigationItem.rightBarButtonItem = addButton
        
        didGetCircle()
    }
    
    
    func didGetCircle() {
        if let circle = self.circle {
            let circleId = circle["id"] as String
            
            self.title = circle["name"] as? String
            println(self.title)
            println(circleId)
            
            let url = NSURL(string: baseUrl + "/data/" + circleId + "/stories");
            let task = session?.dataTaskWithURL(url!) {(data, response, error) in
                self.didGetStories(data)
            }
            task?.resume();
        }
    }
    
    func copyTask(source: AnyObject, destination: AnyObject) {
        destination.setValue(source["sortKey"] as Int, forKey: "sortKey")
        
        destination.setValue(source["id"] as String, forKey: "id")
        destination.setValue(source["summary"] as String, forKey: "summary")
        
        if let owner = source["owner"] as? String {
            destination.setValue(owner, forKey: "owner")
        }
        
        if let status = source["status"] as? String {
            destination.setValue(status, forKey: "status")
        }
        
        if let description = source["description"] as? String {
            destination.setValue(description, forKey: "longDescription")
        }
        
        // isMilepost ...
        if let isMilepostInt = source["isDeadline"] as? Int {
            if (isMilepostInt == 1) {
                destination.setValue(true, forKey: "isMilepost")
            }
            else {
                destination.setValue(false, forKey: "isMilepost")
            }
        }
        else {
            destination.setValue(false, forKey: "isMilepost")
        }

        
        // Next meeting ...
        if let isNextMeetingInt = source["isNextMeeting"] as? Int {
            if (isNextMeetingInt == 1) {
                destination.setValue(true, forKey: "isNextMeeting")
            }
            else {
                destination.setValue(false, forKey: "isNextMeeting")
            }
        }
        else {
            destination.setValue(false, forKey: "isNextMeeting")
        }
        

    }
    
    
    func didGetStories(data: NSData) {
        // TODO: Use an error pointer to blah blah
        let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil)
        
        var jsonDict: NSDictionary = json as NSDictionary
        var firstTask: AnyObject? = NSDictionary()
        
        for (id, task) in jsonDict {
            if (task["isFirstStory"] as Int == 1) {
                firstTask = task
            }
        }
        
        var taskArray: NSMutableArray = NSMutableArray();
        
        var currentTask: AnyObject? = firstTask
        var hasMoreTasks: Bool = true
        
        var count: Int = 0

        while (currentTask !== nil) {
            var currentTaskDict: NSMutableDictionary = NSMutableDictionary()
            currentTaskDict.addEntriesFromDictionary(currentTask as NSDictionary)
            currentTaskDict.setValue(count, forKey: "sortKey");
            
            taskArray.addObject(currentTaskDict)
            currentTask = jsonDict[currentTaskDict["nextId"] as String]
            count++
        }
        
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        var error: NSError? = nil
        
        let requestAll: NSFetchRequest = NSFetchRequest(entityName: entity.name!)
        let fetchedObjects = context.executeFetchRequest(requestAll, error: &error)
        
        if let existingTasks = fetchedObjects {
            for existingTask in existingTasks {
                existingTask.setValue("delete", forKey: "syncStatus")
            }
            
            for task in taskArray {
                var serverTaskFound = false
                
                for existingTask in existingTasks {
                    let task = task as NSDictionary
                    let taskId = task["id"] as String
                    let existingTaskId = existingTask.valueForKey("id") as String
                    
                    if (taskId == existingTaskId) {
                        copyTask(task, destination: existingTask);
                        existingTask.setValue("ok", forKey: "syncStatus")
                        
                        serverTaskFound = true
                        
                        break
                    }
                }
                
                if (!serverTaskFound) {
                    insertTask(task as NSDictionary)
                }
            }
            
            for existingTask in existingTasks {
                if existingTask.valueForKey("syncStatus") as String == "delete" {
                    context.deleteObject(existingTask as NSManagedObject)
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // TODO: Guarantee this is called after things are updated.
        // It is fine with small data sets
        let context = self.fetchedResultsController.managedObjectContext
        var error: NSError? = nil
        if !context.save(&error) {
            // TODO: ...
            abort()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertTask(task: NSDictionary) {
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as NSManagedObject
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        copyTask(task, destination: newManagedObject);
    }
    
    func insertNewObject(sender: AnyObject) {
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as NSManagedObject
             
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        newManagedObject.setValue(NSDate(), forKey: "timeStamp")
             
        // Save the context.
        var error: NSError? = nil
        if !context.save(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
            let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject
            (segue.destinationViewController as DetailViewController).detailItem = object
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject)
                
            var error: NSError? = nil
            if !context.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                //println("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject

        cell.textLabel!.text = object.valueForKey("summary") as? String

        cell.backgroundColor = UIColor.whiteColor()
        cell.textLabel!.textColor = UIColor.blackColor()
        
        if let isMilepost = object.valueForKey("isMilepost") as? Bool {
            if (isMilepost) {
                cell.backgroundColor = UIColor.darkGrayColor()
                cell.textLabel!.textColor = UIColor.whiteColor()
            }
        }
        
        if let isNextMeeting = object.valueForKey("isNextMeeting") as? Bool {
            if (isNextMeeting) {
                cell.backgroundColor = UIColor.blackColor()
                cell.textLabel!.textColor = UIColor.whiteColor()
            }
        }
        
        if let status = object.valueForKey("status") as? String {
            switch status {
                case "done":
                    cell.backgroundColor = UIColor.purpleColor()
                    cell.textLabel!.textColor = UIColor.whiteColor()
                    break
                case "active":
//                    cell.backgroundColor = UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1.0)
//                    cell.textLabel!.textColor = UIColor.whiteColor()
                    break
            default:
                break
            }
        }
        
        //
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Task", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "sortKey", ascending: true)
        let sortDescriptors = [sortDescriptor]
        
        fetchRequest.sortDescriptors = [sortDescriptor]
    
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
    	var error: NSError? = nil
    	if !_fetchedResultsController!.performFetch(&error) {
    	     // Replace this implementation with code to handle the error appropriately.
    	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             //println("Unresolved error \(error), \(error.userInfo)")
    	     abort()
    	}
        
        return _fetchedResultsController!
    }    
    var _fetchedResultsController: NSFetchedResultsController? = nil

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                let path = indexPath!
                if let cell = tableView.cellForRowAtIndexPath(path) {
                    self.configureCell(cell, atIndexPath: indexPath!)
                }
                else {
                    println("PATH NOT FOUND")
                    println(path)
                }
                
                break
            case .Move:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            default:
                return
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         self.tableView.reloadData()
     }
     */

}

