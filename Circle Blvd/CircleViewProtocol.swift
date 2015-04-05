//
//  CircleViewProtocol.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 4/4/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import CoreData

@objc protocol CircleViewProtocol: SessionViewProtocol {
    
    var managedObjectContext: NSManagedObjectContext? { get set }
    var circle: NSDictionary? { get set }
}