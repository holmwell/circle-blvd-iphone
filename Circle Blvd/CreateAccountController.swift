//
//  CreateAccountController.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 4/22/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import UIKit
import CoreData

class CreateAccountController: UIViewController, CircleBlvdClientProtocol {
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var client: CircleBlvdClient?
    
    @IBOutlet weak var circleNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var memberNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    
    @IBAction func emailEntered(sender: AnyObject) {
        passwordField.becomeFirstResponder()
    }
    @IBAction func passwordEntered(sender: AnyObject) {
        memberNameField.becomeFirstResponder()
    }
    
    @IBAction func memberNameEntered(sender: AnyObject) {
        circleNameField.becomeFirstResponder()
    }
    
    @IBAction func circleNameEntered(sender: AnyObject) {
        tryCreateCircle()
    }
    
    @IBAction func joinPressed(sender: AnyObject) {
        tryCreateCircle()
    }
    
    func trim(s: String) -> String {
        return s.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Could not create", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        let alertAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in }
        
        alert.addAction(alertAction)
        self.presentViewController(alert, animated: false, completion: { () -> Void in })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if let dest = segue.destinationViewController as? CircleViewProtocol {
            dest.baseUrl = self.client?.baseUrl
            dest.session = self.client?.session
            dest.profile = self.client?.profile
            dest.managedObjectContext = self.managedObjectContext
            if let circles = self.client?.circles {
                for circle in circles {
                    var circleDict = NSMutableDictionary()
                    circleDict["name"] = circle.value
                    circleDict["id"] = circle.key
                    dest.circle = circleDict
                }
            }
        }
    }
    
    func circleCreated() {
        performSegueWithIdentifier("toCircleView", sender: self)
    }
    
    func tryCreateCircle() {
        var circleName = trim(circleNameField.text)
        var emailAddress = trim(emailField.text)
        var password = passwordField.text
        var memberName = trim(memberNameField.text)
        
        if (circleName.isEmpty) {
            circleName = "(without name)"
        }
        if (memberName.isEmpty) {
            memberName = "(no name)"
        }
        
        if (emailAddress.isEmpty) {
            showAlert("Sorry, we need an email address to create an account for you.")
            return
        }
        
        let request = client!.getCreateRequest(circleName, emailAddress: emailAddress, password: password, memberName: memberName)
        
        if let session = client!.session {
            let dataTask = session.dataTaskWithRequest(request, completionHandler: {
                (data: NSData!, response:NSURLResponse!, error: NSError!) -> Void in
                
                if let httpResponse = response as? NSHTTPURLResponse {
                    if (httpResponse.statusCode == 200) {
                        // Good to go
                        dispatch_async(dispatch_get_main_queue()) {
                            self.circleCreated()
                        }
                    }
                    else {
                        if (httpResponse.statusCode == 400 || httpResponse.statusCode == 403) {
                            if let message = NSString(data: data, encoding: NSUTF8StringEncoding) {
                                self.showAlert(String(message))
                            }
                            else {
                                self.showAlert("Sorry, things aren't working right now.")
                            }
                        }
                        else {
                            self.showAlert("Sorry, our computers aren't working. Please try again at a later time.ß")
                        }
                    }
                }
                else {
                    self.showAlert("Sorry, we could not connect to circleblvd.org. Please try again later.")
                }
            })
            dataTask.resume()
        }
    }
    

}