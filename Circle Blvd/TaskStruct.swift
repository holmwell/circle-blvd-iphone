//
//  Task.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 3/31/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import Argo
import Runes

struct TaskStruct {
    let id: String
    let circleId: String
    let nextId: String
    let isFirstStory: Bool
    let summary: String
    let description: String?
    let status: String?
    let isMilepost: Bool?
}

extension TaskStruct {
    static func create(id: String)
        (circleId: String)
        (nextId: String)
        (isFirstStory: Bool)
        (summary: String)
        (description: String?)
        (status: String?)
        (isMilepost: Bool?) -> TaskStruct {
        return TaskStruct(id: id,
            circleId: circleId,
            nextId: nextId,
            isFirstStory: isFirstStory,
            summary: summary,
            description: description,
            status: status,
            isMilepost: isMilepost)
    }
    
    
//    static func decode(j: NSDictionary) -> Task? {
//        if let id = j["id"] as Int {
//            if let name = j["name"] as String {
//                return Task(id: id,
//                    name: name)
//            }
//        }
//        
//        return .None
//    }
//    
    
    static func decode(j: JSONValue) -> TaskStruct? {
        println(j);
        return TaskStruct(id: "ok", circleId: "ok", nextId: "ok", isFirstStory: false, summary: "What", description: "Desc", status: "", isMilepost: false);
    }
    
//    static func decode(j: JSONValue) -> Task? {
//        return Task.create
//            <^> j <| "id"
//            <*> j <| "projectId"
//            <*> j <| "isFirstStory"
//            <*> j <| "summary"
//            <*> j <|? "description"
//            <*> j <|? "status"
//            <*> j <|? "isDeadline"
//    }
}
