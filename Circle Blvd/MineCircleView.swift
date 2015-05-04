//
//  MineCircleView.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 4/5/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import CoreData
import UIKit
import Foundation


class MineCircleView: CircleView {

    
    override var fetchedResultsController: NSFetchedResultsController {
        if _myFetchedResultsController != nil {
            return _myFetchedResultsController!
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

        let predicateFormat = "(isNextMeeting = true) OR (isMilepost = true) OR (owner = %@)"

        if let profile = profile {
            if let profileName = profile["name"] as? String {
                let ownerPredicate = NSPredicate(format: predicateFormat, profileName)
                fetchRequest.predicate = ownerPredicate
            }
        }
        
        // TODO: Actually have a Cache
        // We don't have one because we need to better manage our deleted objects
        let cacheName = predicateFormat + " Cache"
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _myFetchedResultsController = aFetchedResultsController
        
        var error: NSError? = nil
        if !_myFetchedResultsController!.performFetch(&error) {
            // TODO: Replace this implementation with code to handle the error appropriately.
            println("Unresolved error \(error), \(error?.userInfo)")
        }
        
        return _myFetchedResultsController!
    }
    var _myFetchedResultsController: NSFetchedResultsController? = nil
    
}
