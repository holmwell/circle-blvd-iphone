//
//  CircleVlew.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 4/4/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import CoreData
import UIKit

class CircleView: UITableView,
    UITableViewDelegate,
    UITableViewDataSource,
    NSFetchedResultsControllerDelegate, CircleViewProtocol {
    
    var session: NSURLSession? = nil
    var baseUrl: String? = ""
    var profile: NSDictionary?
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var circle: NSDictionary?

    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.dataSource = self
        // TODO: Do we need this?
        // self.delegate = self
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func reloadData() {
        super.reloadData()
        didGetCircle()
    }
    
    
    func didGetCircle() {
        if let circle = self.circle {
            if let circleId = circle["id"] as? String {
                let url = NSURL(string: baseUrl! + "/data/" + circleId + "/stories");
                let task = session?.dataTaskWithURL(url!) {(data, response, error) in
                    if let data = data {
                        self.didGetStories(data)
                    }
                    else {
                        println("Could not get stories")
                    }
                }
                task?.resume();
            }
            else {
                println("Circle ID was not specified")
            }
            
            // TODO:
//            self.title = circle["name"] as? String
        }
        else {
            println("No circle specified in CircleView")
        }
    }
    
    // Copy a Json dictionary into a NSManagedObject Task entity
    func copyTask(source: AnyObject, destination: AnyObject) {
        destination.setValue(source["sortKey"] as Int, forKey: "sortKey")
        
        destination.setValue(source["id"] as String, forKey: "id")
        destination.setValue(source["summary"] as String, forKey: "summary")
        
        if let circleId = source["projectId"] as? String {
            destination.setValue(circleId, forKey: "circleId")
        }
        
        if let listId = source["listId"] as? String {
            destination.setValue(listId, forKey: "listId")
        }
        
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
        
        // Comments
        if let comments = source["comments"] as? NSArray {
            
            let context = self.managedObjectContext
            let commentsModel = destination.mutableOrderedSetValueForKey("comments")
            
            // TODO: Make sure we're not deleting while something else is
            // changing the context. Check to see if we can wait for something
            commentsModel.enumerateObjectsUsingBlock { (elem, index, stop) -> Void in
                //context?.deleteObject(elem as NSManagedObject)
                context?.deleteObject(elem as NSManagedObject)
                return
            }
            
            for comment in comments {
                
                var commentEntity = NSEntityDescription.insertNewObjectForEntityForName("Comment", inManagedObjectContext: self.managedObjectContext!) as? NSManagedObject
                
                if let entity = commentEntity {
                    if let createdBy = comment["createdBy"] as? NSDictionary {
                        if let author = createdBy["name"] as? String {
                            entity.setValue(author, forKey: "authorName")
                        }
                    }
                    
                    if let text = comment["text"] as? String {
                        entity.setValue(text, forKey: "text")
                    }
                    
                    entity.setValue(destination as Task, forKey: "task")
                }
            }
        }
    }
    
    func shouldIncludeTask(task: NSDictionary) -> Bool {
        return true
    }
    
    
    func didGetStories(data: NSData) {
        println("DID GET STORIES")
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
            if let task = currentTask as? NSDictionary {
                currentTaskDict.addEntriesFromDictionary(task)
                currentTaskDict.setValue(count, forKey: "sortKey");
                
                if (shouldIncludeTask(task)) {
                    taskArray.addObject(currentTaskDict)
                }
                currentTask = jsonDict[currentTaskDict["nextId"] as String]
                count++
            }
            else {
                currentTask = nil
            }
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
        
        dispatch_async(dispatch_get_main_queue()) {
            var error: NSError? = nil
            if !context.save(&error) {
                // TODO: ...
                abort()
            }
        }
    }
    
    
    func insertTask(task: NSDictionary) {
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as NSManagedObject
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        copyTask(task, destination: newManagedObject);
    }
    
    
    // MARK: - Segues
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "showDetail" {
//            if let indexPath = self.actualTableView.indexPathForSelectedRow() {
//                let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject
//                let destination = segue.destinationViewController as DetailViewController
//                destination.detailItem = object
//                destination.baseUrl = self.baseUrl
//                destination.session = self.session
//                destination.profile = self.profile
//            }
//        }
//    }
    
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        println("section number")
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        println("number")
        let sectionInfo = self.fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        println(sectionInfo.numberOfObjects)
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
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
        // println("configure cell ...")
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject

        cell.textLabel!.text = object.valueForKey("summary") as? String

        cell.selectionStyle = UITableViewCellSelectionStyle.None
        
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
        
        if let owner = object.valueForKey("owner") as? String {
            if let profile = self.profile {
                if let profileName = profile["name"] as? String {
                    if (owner.compare(profileName, options: NSStringCompareOptions.CaseInsensitiveSearch) == NSComparisonResult.OrderedSame) {
                        
                        cell.textLabel!.textColor = UIColor(red: 0.118, green: 0.412, blue: 0.71, alpha: 1.0)
                    }
                }
            }
        }
        
        if let status = object.valueForKey("status") as? String {
            switch status {
            case "done":
                if let text = cell.textLabel!.text {
                    // cell.textLabel!.text = "\u{00B7} " + text
                    cell.textLabel!.text = "\u{2022} " + text
                }
                
                break
            case "active":
                break
            default:
                break
            }
        }
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        println("fetchedResultsController")
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        println("building fetched results controller")
        
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
        
        println("1...")
        
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        // TODO: Actually have a cache
        // We don't have one because we need to better manage our deleted objects
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        println("2...")
        
        var error: NSError? = nil
        if !_fetchedResultsController!.performFetch(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development
            // println("Unresolved error \(error), \(error.userInfo)")

            // abort()
        }
        
        println("3...")
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        println("will change content ...")
        self.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        println("controller ...")
        switch type {
        case .Insert:
            self.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        // println("controller 2 ...")
        switch type {
        case .Insert:
            self.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            // println("Insert ...")
        case .Delete:
            self.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            // println("Delete ...")
        case .Update:
            // TODO: What is going on here?
            // println("Update ...")
            let path = indexPath!
            if let cell = self.cellForRowAtIndexPath(path) {
                self.configureCell(cell, atIndexPath: indexPath!)
            }
            else {
                // TODO ...
//                                    println("PATH NOT FOUND")
//                                    println(path)
            }
            
            break
        case .Move:
            // println("Move ...")
            self.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            self.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        println("did change content")
        self.endUpdates()
    }
    
    /*
    // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
    // In the simplest, most efficient, case, reload the table view.
    self.tableView.reloadData()
    }
    */
}