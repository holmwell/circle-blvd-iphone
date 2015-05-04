//
//  AddTaskController.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 4/12/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import UIKit
import CoreData

class AddTaskController: UIViewController, CircleViewProtocol {

    var session: NSURLSession? = nil
    var baseUrl: String? = ""
    var profile: NSDictionary?
    
    var managedObjectContext: NSManagedObjectContext?
    var circle: NSDictionary?
    
    @IBOutlet weak var summaryField: UITextField!
    @IBOutlet weak var descriptionField: UITextView!
    @IBOutlet weak var ownerSwitch: UISwitch!
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    @IBAction func addTask(sender: AnyObject) {
        println("Add")
        
        saveTask()
    }
    
    func saveTask() {
        func getSaveRequest() -> NSURLRequest {
            
            var request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl! + "/data/story")!)
            
            request.HTTPMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            var parameters = NSMutableDictionary()
            // parameters["id"] = task.id
            parameters["summary"] = summaryField.text
            parameters["description"] = descriptionField.text
            if (ownerSwitch.on) {
                parameters["owner"] = profile!["name"] as! String
                parameters["status"] = "assigned"
            }
            // parameters["owner"] = valueOrEmptyString(task.owner)
            // parameters["status"] = valueOrEmptyString(task.status)
            parameters["projectId"] = circle!["id"] as! String
            
            // pass dictionary to nsdata object and set it as request body
            var err: NSError?
            request.HTTPBody = NSJSONSerialization.dataWithJSONObject(parameters, options: nil, error: &err)
            
            return request
        }
        
        
        if let session = session {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            let request = getSaveRequest()
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
            
            self.performSegueWithIdentifier("unwindToMaster", sender: self)
        }
    }
    
    
    func textViewDidChange(textView: UITextView) {
        
    }
}