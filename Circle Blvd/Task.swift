//
//  Task.swift
//  Circle Blvd
//
//  Created by Swing on 4/3/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import Foundation
import CoreData

class Task: NSManagedObject {

    @NSManaged var id: String
    @NSManaged var isMilepost: NSNumber
    @NSManaged var isNextMeeting: NSNumber
    @NSManaged var longDescription: String
    @NSManaged var owner: String
    @NSManaged var sortKey: NSNumber
    @NSManaged var status: String
    @NSManaged var summary: String
    @NSManaged var syncStatus: String
    @NSManaged var comments: NSOrderedSet
}
