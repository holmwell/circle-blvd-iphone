//
//  Comment.swift
//  Circle Blvd
//
//  Created by Swing on 4/3/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import Foundation
import CoreData

class Comment: NSManagedObject {

    @NSManaged var timestamp: NSDate
    @NSManaged var authorName: String
    @NSManaged var text: String
    @NSManaged var task: Task

}
