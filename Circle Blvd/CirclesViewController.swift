//
//  CirclesViewController.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 4/2/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import UIKit
import CoreData
import Foundation

class CirclesViewController: UITableViewController, NSFetchedResultsControllerDelegate, SessionViewProtocol {
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var session: NSURLSession? = nil
    var baseUrl: String? = ""
    var profile: NSDictionary?
    
    var circles: NSDictionary?
    
    
    @IBOutlet var taskTableView: UITableView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Refresh the circles. Delete then insert.
        var error: NSError? = nil
        let context = self.fetchedResultsController.managedObjectContext
        let requestAll: NSFetchRequest = NSFetchRequest(entityName: "Circle")
        let fetchedObjects = context.executeFetchRequest(requestAll, error: &error)
        if let fetchedCircles = fetchedObjects {
            for circle in fetchedCircles {
                context.deleteObject(circle as! NSManagedObject)
            }
        }
        
        if let circles = circles {
            for pair in circles {
                var circle = NSMutableDictionary()
                circle.setValue(pair.key, forKey: "id")
                circle.setValue(pair.value, forKey: "name")
                insertCircle(circle)
            }
        }
        
        if !context.save(&error) {
            // TODO: ...
            println("Unresolved error \(error), \(error?.userInfo)")
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func insertCircle(circle: NSDictionary) {
        let context = self.fetchedResultsController.managedObjectContext
        let entity = self.fetchedResultsController.fetchRequest.entity!
        
        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as! NSManagedObject
        
        // If appropriate, configure the new managed object.
        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
        // TODO: Add a custom class for Circle
        newManagedObject.setValue(circle["name"] as! String, forKey: "name")
        newManagedObject.setValue(circle["id"] as! String, forKey: "id")
    }
    
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        let dest = segue.destinationViewController as! CircleViewProtocol
        dest.baseUrl = self.baseUrl
        dest.session = self.session
        dest.profile = self.profile
        dest.managedObjectContext = self.managedObjectContext
        
        if let indexPath = self.tableView.indexPathForSelectedRow() {
            let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
            var circle = NSMutableDictionary();
            circle["name"] = object.valueForKey("name") as! String
            circle["id"] = object.valueForKey("id") as! String
            dest.circle = circle
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
            
            var error: NSError? = nil
            if !context.save(&error) {
                // TODO: Handle the error
                println("Unresolved error \(error), \(error?.userInfo)")
            }
        }
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let object = self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject
        
        cell.textLabel!.text = object.valueForKey("name") as? String
    }
    
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Circle", inManagedObjectContext: self.managedObjectContext!)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let sortDescriptors = [sortDescriptor]
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Circles")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        var error: NSError? = nil
        if !_fetchedResultsController!.performFetch(&error) {
            println("Unresolved error \(error), \(error?.userInfo)")
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

