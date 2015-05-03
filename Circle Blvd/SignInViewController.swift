//
//  SignInViewController.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 3/30/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import UIKit
import CoreData

class SignInViewController: UIViewController {
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var client: CircleBlvdClient = CircleBlvdClient()
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var passwordField: UITextField!
    
    @IBAction func tapRecognized(sender: UITapGestureRecognizer) {
        // Hide the keyboard if one of the text field's is 
        // selected and we tap outside of it.
        self.view.endEditing(false)
    }
    
    @IBAction func usernameEnded(sender: AnyObject) {
        passwordField.becomeFirstResponder()
    }
    
    @IBAction func passwordEnded(sender: AnyObject) {
        signInButton(sender)
    }
    
    @IBAction func signInButton(sender: AnyObject) {
        if let pass = self.passwordTextField {
            if let email = self.emailTextField {
                client.signIn(email.text, password: pass.text) {
                    err, result in
                    if (err) {
                        // TODO: Show dialog
                        println(result)
                    }
                    else {
                        self.toSegue()
                    }
                }
            }
        }
    }
    
    
    func toSegue() {
        // HACK: spaces being used for padding. Please fix.
        let circlesButton = UIBarButtonItem(title: " Circles ", style: UIBarButtonItemStyle.Plain,
            target: self, action: "actuallyToSegue")
        
        self.navigationItem.rightBarButtonItem = circlesButton
        actuallyToSegue()
    }
    
    func actuallyToSegue() {
        // toSegue() is often called from a background thread (after
        // a network request). Since performing segues from background
        // threads leads to crashes, we dispatch it to the main queue
        dispatch_async(dispatch_get_main_queue()) {
            if let circles = self.client.circles {
                if circles.count == 1 {
                    self.performSegueWithIdentifier("toMasterSegue", sender: self)
                }
                else {
                    self.performSegueWithIdentifier("toCirclesSegue", sender: self)
                }
            }
            else {
                println("Attempt to segue without circles")
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        // Pass data to the next controller. We want to keep the session and
        // the data store around.
        if let segueName = segue.identifier {
            if segueName == "toMasterSegue" {
                // We get here if we're only in one circle.
                let dest = segue.destinationViewController as! CircleViewProtocol
                dest.baseUrl = self.client.baseUrl
                dest.session = self.client.session
                dest.profile = self.client.profile
                dest.managedObjectContext = self.managedObjectContext
                if let circles = client.circles {
                    for circle in circles {
                        var circleDict = NSMutableDictionary()
                        circleDict["name"] = circle.value
                        circleDict["id"] = circle.key
                        dest.circle = circleDict
                    }
                }
            }
            else if segueName == "toCreateAccount" {
                var dest = segue.destinationViewController as! CreateAccountController
                dest.client = self.client
                dest.managedObjectContext = self.managedObjectContext
            }
            else {
                // toCirclesSegue
                let dest = segue.destinationViewController as! CirclesViewController
                dest.baseUrl = self.client.baseUrl
                dest.session = self.client.session
                dest.profile = self.client.profile
                dest.circles = self.client.circles
                dest.managedObjectContext = self.managedObjectContext
            }
        }
    }
    
    
    func configureView() {

    }

    
    override func viewDidAppear(animated: Bool) {
        // println("VOILA")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        client.getUserData {
            err in
            if (err) {
                println("Server returned an error code")
            }
            else {
                self.toSegue()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}