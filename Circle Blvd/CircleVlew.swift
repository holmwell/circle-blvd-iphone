//
//  CircleVlew.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 4/4/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import CoreData
import UIKit
import Socket_IO_Client_Swift

class CircleView: UITableView,
    UITableViewDelegate,
    UITableViewDataSource,
    NSFetchedResultsControllerDelegate, CircleViewProtocol {
    
    var session: NSURLSession? = nil
    var baseUrl: String? = ""
    var profile: NSDictionary?
    
    var socket: SocketIOClient?
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var circle: NSDictionary? {
        didSet {
            if let circle = circle {
                if let circleId = circle["id"] as? String {
                    let defaults = NSUserDefaults.standardUserDefaults()
                    let filter = defaults.integerForKey(circleId + "-viewFilter")
                    if let filter = CircleViewFilter(rawValue: filter) {
                        viewFilter = filter
                    }
                }
                invalidateCircleCache()
                didGetCircle()
            }
        }
    }

    func invalidateCircleCache() {
        _fetchedResultsController = nil
    }
    
    
    required init(coder aDecoder: NSCoder) {
        self.viewFilter = CircleViewFilter.AllTasks
        
        super.init(coder: aDecoder)
        self.dataSource = self
        self.delegate = self
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func reloadData() {
        didGetCircle()
        super.reloadData()
    }
    
    func didFinishGetCircle() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        if let circle = circle {
            if let circleId = circle["id"] as? String {
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setValue(circleId, forKey: "most-recent-circle")
            }
        }
    }
    
    func initRealtimeUpdates(circleId: String) {
        if let baseUrl = baseUrl {
            if socket == nil {
                socket = SocketIOClient(socketURL: baseUrl)
                if let socket = socket {
                    socket.on("connect") {data, ack in
                        println("socket connected")
                        let message = [
                            "circle": circleId
                        ]
                        socket.emit("join-circle", message)
                    }
                    
                    socket.on("o") { data, ack in
                        println("oooooo")
                        self.reloadData()
                    }
                    
                    socket.connect()
                }
            }
            else {
                let message = [
                    "circle": circleId
                ]
                socket!.emit("join-circle", message)
            }
        }
    }
    
    func didGetCircle() {
        if let circle = self.circle {
            if let circleId = circle["id"] as? String {
                let defaults = NSUserDefaults.standardUserDefaults()
                if let mostRecentCircleId = defaults.valueForKey("most-recent-circle") as? String {
                    if (mostRecentCircleId != circleId) {
                        // Clear out our context.
                        if let context = self.managedObjectContext {
                            var error: NSError? = nil
                            
                            let requestAll: NSFetchRequest = NSFetchRequest(entityName: "Task")
                            let fetchedObjects = context.executeFetchRequest(requestAll, error: &error)
                            if let existingTasks = fetchedObjects {
                                for task in existingTasks {
                                    context.deleteObject(task as! NSManagedObject)
                                }
                            }
                        }
                    }
                }
                
                let url = NSURL(string: baseUrl! + "/data/" + circleId + "/stories");
                // TODO: Be cool and deal with simultaneous requests
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                let task = session?.dataTaskWithURL(url!) {(data, response, error) in
                    if let data = data {
                        self.didGetStories(data)
                        self.initRealtimeUpdates(circleId)
                    }
                    else {
                        println("Could not get stories")
                    }
                    self.didFinishGetCircle()
                }
                task?.resume();
            }
            else {
                println("Circle ID was not specified")
            }
        }
        else {
            println("No circle specified in CircleView")
        }
    }
    
    // Copy a Json dictionary into a NSManagedObject Task entity
    func copyTask(source: AnyObject, destination: AnyObject) {
        // TODO: Get rid of all this casting and use some classes
        destination.setValue(source["sortKey"] as! Int, forKey: "sortKey")
        
        destination.setValue(source["id"] as! String, forKey: "id")
        destination.setValue(source["summary"] as! String, forKey: "summary")
        
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
        
        if let isFirstTask = source["isFirstStory"] as? NSNumber {
            destination.setValue(isFirstTask.boolValue, forKey: "isFirstTask")
        }
        else {
            destination.setValue(false, forKey: "isFirstTask")
        }
        
        if let nextId = source["nextId"] as? String {
            destination.setValue(nextId, forKey: "nextId")
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
                context?.deleteObject(elem as! NSManagedObject)
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
                    
                    entity.setValue(destination as! Task, forKey: "task")
                }
            }
        }
    }
    
    func shouldIncludeTask(task: NSDictionary) -> Bool {
        return true
    }
    
    
    func didGetStories(data: NSData) {
        println("DID GET STORIES")
        
        // TODO: Use an error pointer
        let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: nil)
        if (json == nil) {
            println("didGetStories: No data")
            return
        }
        
        var jsonDict: NSDictionary = json as! NSDictionary
        var firstTask: AnyObject? = NSDictionary()
        
        for (id, task) in jsonDict {
            if (task["isFirstStory"] as! Int == 1) {
                firstTask = task
            }
        }
        
        var taskArray: NSMutableArray = NSMutableArray();
        
        var currentTask: AnyObject? = firstTask
        var hasMoreTasks: Bool = true
        
        var count: Int = 0
        
        while (currentTask != nil) {
            var currentTaskDict: NSMutableDictionary = NSMutableDictionary()
            if let task = currentTask as? [String: AnyObject] {
                currentTaskDict.addEntriesFromDictionary(task)
                currentTaskDict.setValue(count, forKey: "sortKey");
                
                if (shouldIncludeTask(task)) {
                    taskArray.addObject(currentTaskDict)
                }
                currentTask = jsonDict[currentTaskDict["nextId"] as! String]
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
                    let task = task as! NSDictionary
                    let taskId = task["id"] as! String
                    let existingTaskId = existingTask.valueForKey("id") as! String
                    
                    if (taskId == existingTaskId) {
                        copyTask(task, destination: existingTask);
                        existingTask.setValue("ok", forKey: "syncStatus")
                        
                        serverTaskFound = true
                        
                        break
                    }
                }
                
                if (!serverTaskFound) {
                    insertTask(task as! NSDictionary)
                }
            }
            
            for existingTask in existingTasks {
                if let existingTask = existingTask as? Task {
                    if (existingTask.syncStatus == "delete") {
                        context.deleteObject(existingTask)
                    }
                }
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            var error: NSError? = nil
            if !context.save(&error) {
                // TODO: ...
                println("Unresolved error \(error), \(error?.userInfo)")
            }
        }
    }
    
    
    func insertTask(task: NSDictionary) {
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as! NSManagedObject
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        copyTask(task, destination: newManagedObject);
    }
    
    
    // MARK: - Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // println("section number")
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func numberOfObjectsInTableView() -> Int {
        return tableView(self, numberOfRowsInSection: 0)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // println("number")
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        if (viewFilter == CircleViewFilter.MyTasks) {
            return false
        }
        return true
    }

    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be moveable.
        return true
    }
    
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return UITableViewCellEditingStyle.None
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
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
                println(message)
                // TODO: ...
                // self.presentViewController(alert, animated: false, completion: { () -> Void in })
            }
            else {
                let context = self.fetchedResultsController.managedObjectContext
                var error: NSError? = nil
                if !context.save(&error) {
                    // TODO: Replace this implementation with code to handle the error appropriately.
                    println("Unresolved error \(error), \(error?.userInfo)")
                }
            }
        }
    }
    
    // TODO: Refactor, put this somewhere nice
    func valueOrEmptyString(optional: NSString?) -> NSString {
        if (optional != nil) {
            return optional!
        }
        else {
            return ""
        }
    }
    
    func tableView(tableView: UITableView,
        moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
            
            if fromIndexPath.section == toIndexPath.section &&
                fromIndexPath.row == toIndexPath.row {
                    // Do nothing
                    return
            }
            
            
            let cache = self.fetchedResultsController
            
            // TODO: Move this into the task object
            func moveTask(task: Task, newNextId: String) {
                // Update server
                func getMoveRequest(task: Task) -> NSURLRequest {
                    
                    var request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl! + "/data/story/move")!)
                    
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
                    
                    var body = NSMutableDictionary()
                    body["story"] = parameters
                    body["newNextId"] = newNextId
                    
                    // pass dictionary to nsdata object and set it as request body
                    var err: NSError?
                    request.HTTPBody = NSJSONSerialization.dataWithJSONObject(body, options: nil, error: &err)
                    
                    return request
                }
                
                
                if let session = session {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                    let request = getMoveRequest(task)
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

            func updateModel(movedTask: Task, oldPreviousIndexPath: NSIndexPath?,
                oldNextIndexPath: NSIndexPath?, previousIndexPath: NSIndexPath?, nextTask: Task?) {

                    var oldNextTask: Task?
                    var oldPreviousTask: Task?
                    var previousTask: Task?
                    
                    if let oldNextIndex = oldNextIndexPath {
                        oldNextTask = self.fetchedResultsController.objectAtIndexPath(oldNextIndex) as? Task
                    }
                    
                    if let oldPreviousIndex = oldPreviousIndexPath {
                        oldPreviousTask = self.fetchedResultsController.objectAtIndexPath(oldPreviousIndex) as? Task
                    }
                    
                    if let previousIndex = previousIndexPath {
                        previousTask = self.fetchedResultsController.objectAtIndexPath(previousIndex) as? Task
                    }
                    
                    // 1. Update the previous location
                    if let oldNext = oldNextTask {
                        if (movedTask.isFirstTask.boolValue) {
                            movedTask.isFirstTask = false
                            oldNext.isFirstTask = true
                        }
                        
                        if let oldPrevious = oldPreviousTask {
                            oldPrevious.nextId = oldNext.id
                        }
                    }
                    else if let oldPrevious = oldPreviousTask {
                        oldPrevious.nextId = "last-" + oldPrevious.circleId
                    }

                    // 2. Update the moved task
                    if let next = nextTask {
                        movedTask.nextId = next.id
                    }
                    else {
                        movedTask.nextId = "last-" + movedTask.circleId
                    }
                    
                    // 3. Update the new location
                    if let previous = previousTask {
                        previous.nextId = movedTask.id
                    }
                    else {
                        movedTask.isFirstTask = true
                    }
                    
                    
                    // Update sort index
                    let cache = self.fetchedResultsController
                    var startIndex: Int = 0
                    var endIndex: Int = 0
                    var nextIndex: Int = 0
                    
                    if let next = nextTask {
                        nextIndex = next.sortKey!.integerValue
                    }
                    else {
                        nextIndex = self.numberOfRowsInSection(0)
                    }
                    
                    if (movedTask.sortKey?.integerValue < nextIndex) {
                        // Update from old next task to moved task
                        startIndex = oldNextIndexPath!.row
                        endIndex = previousIndexPath!.row
                        
                        var currentIndex = startIndex
                        
                        while (currentIndex <= endIndex) {
                            if let currentTask = cache.objectAtIndexPath(NSIndexPath(forRow: currentIndex, inSection: 0)) as? Task {
                                currentTask.sortKey = currentTask.sortKey!.integerValue - 1
                            }
                            currentIndex = currentIndex + 1
                        }
                        
                        movedTask.sortKey = endIndex

                    }
                    else {
                        // Update from moved task to old previous task
                        startIndex = nextIndex
                        if (nextIndex >= self.numberOfRowsInSection(0)) {
                            startIndex = self.numberOfRowsInSection(0) - 1
                        }
                        endIndex = movedTask.sortKey!.integerValue
                        
                        var currentIndex = startIndex
                        
                        while (currentIndex <= endIndex) {
                            if let currentTask = cache.objectAtIndexPath(NSIndexPath(forRow: currentIndex, inSection: 0)) as? Task {
                                currentTask.sortKey = currentTask.sortKey!.integerValue + 1
                            }
                            currentIndex = currentIndex + 1
                        }
                        
                        movedTask.sortKey = startIndex
                    }
            }
            
            
            var nextIndexPath = NSIndexPath(forRow: toIndexPath.row + 1, inSection: toIndexPath.section)
            if (fromIndexPath.row >= toIndexPath.row) {
                nextIndexPath = toIndexPath
            }
            
            var previousIndexPath: NSIndexPath?
            if (nextIndexPath.row > 0) {
                previousIndexPath = NSIndexPath(forRow: nextIndexPath.row - 1, inSection: nextIndexPath.section)
            }
            
            var oldPreviousIndexPath: NSIndexPath?
            var oldNextIndexPath: NSIndexPath?
            
            if fromIndexPath.row > 0 {
                oldPreviousIndexPath = NSIndexPath(forRow: fromIndexPath.row - 1, inSection: fromIndexPath.section)
            }
            
            let taskCount = self.numberOfRowsInSection(0)
            if (fromIndexPath.row != taskCount - 1) {
                oldNextIndexPath = NSIndexPath(forRow: fromIndexPath.row + 1, inSection: fromIndexPath.section)
            }
            
            if let fromObject = cache.objectAtIndexPath(fromIndexPath) as? Task {
                if let toObject = cache.objectAtIndexPath(toIndexPath) as? Task {
                    println(fromObject.summary)
                    if nextIndexPath.row < taskCount {
                        if let nextObject = cache.objectAtIndexPath(nextIndexPath) as? Task {
                            println(nextObject.summary)
                            println(nextObject.sortKey)
                            updateModel(fromObject, oldPreviousIndexPath, oldNextIndexPath, previousIndexPath, nextObject)
                            moveTask(fromObject, nextObject.id)
                        }
                        else {
                            println("NEXT OBJECT IS NULL?")
                        }
                    }
                    else {
                        let lastId = "last-" + fromObject.circleId
                        updateModel(fromObject, oldPreviousIndexPath, oldNextIndexPath, previousIndexPath, nil)
                        moveTask(fromObject, lastId)
                    }
                }
                else {
                    println("TO OBJECT IS NULL?")
                }
            }
            
            //cell.textLabel!.text = object.valueForKey("summary") as? String
            //tableView.cellForRowAtIndexPath(<#indexPath: NSIndexPath#>)
        println("MMOVE")
    }
    
//    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
//        let actions: NSMutableArray = []
//        
//        
//        
//        
//        return actions
//    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        println(editingStyle)
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
            
            var error: NSError? = nil
            if !context.save(&error) {
                // TODO: Replace this implementation with code to handle the error appropriately.
                println("Unresolved error \(error), \(error?.userInfo)")
            }
        }
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        // println("configure cell ...")
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject

        cell.textLabel!.text = object.valueForKey("summary") as? String
// Tried using the right-detail view. Summaries need to be clipped or something if
// this is to work.
//        if let owner = object.valueForKey("owner") as? String {
//            cell.detailTextLabel!.text = owner
//        }
//        else {
//            cell.detailTextLabel!.text = ""
//        }

        cell.selectionStyle = UITableViewCellSelectionStyle.None
        cell.showsReorderControl = true
        
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
    
    var viewFilter: CircleViewFilter {
        didSet {
            switch viewFilter {
            case .AllTasks:
                _fetchPredicate = nil
                break
            case .MyTasks:
                let predicateFormat = "(isNextMeeting = true) OR (isMilepost = true) OR (owner = %@)"
                
                if let profile = profile {
                    if let profileName = profile["name"] as? String {
                        let ownerPredicate = NSPredicate(format: predicateFormat, profileName)
                        _fetchPredicate = ownerPredicate
                    }
                }
                break
            }
            
            if let circle = circle {
                if let circleId = circle["id"] as? String {
                    let defaults = NSUserDefaults.standardUserDefaults()
                    defaults.setInteger(viewFilter.rawValue, forKey: circleId + "-viewFilter")
                    defaults.synchronize()
                }
            }

            // Cache invalidation
            _fetchedResultsController = nil
            
            // Call super because we don't need to get the 
            // tasks again, we just need to refresh our view.
            super.reloadData()
        }
    }
    var _fetchPredicate: NSPredicate?
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        // println("fetchedResultsController")
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        // println("building fetched results controller")
        
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
        
        if let fetchPredicate = _fetchPredicate {
            fetchRequest.predicate = fetchPredicate
        }
        
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
            // TODO: Replace this implementation with code to handle the error appropriately.
            println("Unresolved error \(error), \(error?.userInfo)")
        }
        
        println("3...")
        
        return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController? = nil
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
//        println("will change content ...")
        self.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        // println("controller ...")
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
                if (path.row < numberOfObjectsInTableView()) {
                    self.configureCell(cell, atIndexPath: indexPath!)
                }
                else {
                    println("SAVED THE DAY")
                }
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
//        println("did change content")
        // TODO: This can cause a 'message sent to deallocated instance' error
        // via didGetStories -> context.save
        dispatch_async(dispatch_get_main_queue()) {
            self.endUpdates()
        }
    }
    
    /*
    // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
    // In the simplest, most efficient, case, reload the table view.
    self.tableView.reloadData()
    }
    */
}