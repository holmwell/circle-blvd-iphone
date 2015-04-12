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
    var circles: NSDictionary?
    var profile: NSDictionary?

    let session = NSURLSession.sharedSession()
    let baseUrl = "https://circleblvd.org"
//    let baseUrl = "http://localhost:3000"
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func getSignInRequest(email: String, password: String) -> NSURLRequest {
        var request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/auth/signin")!)
        
        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let bodyStr:String = "email=" + email + "&password=" + password
        request.HTTPBody = bodyStr.dataUsingEncoding(NSUTF8StringEncoding)
    
        return request
    }
    
    @IBAction func passwordEnded(sender: AnyObject) {
        signInButton(sender)
    }
    
    @IBAction func signInButton(sender: AnyObject) {
        if let pass = self.passwordTextField {
            if let email = self.emailTextField {
                
                let request = getSignInRequest(email.text, password: pass.text)
                let dataTask = session.dataTaskWithRequest(request, completionHandler: {
                    (data: NSData!, response:NSURLResponse!, error: NSError!) -> Void in

                    if let httpResponse = response as? NSHTTPURLResponse {
                        if (httpResponse.statusCode == 200) {
                            self.getUserDataAndSegue()
                        }
                        else {
                            // TODO: Show error (invalid login)
                        }
                    }
                    else {
                        println("No internet")
                    }
                })
                dataTask.resume()
            }
        }
    }
    
    // Takes the response from /data/user and saves it to our model
    func didSignIn(userResponseData: NSData) {
        
        let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(userResponseData,
            options: NSJSONReadingOptions(0), error: nil)
        
        if let jsonDict = json as? NSDictionary {
            if let memberships = jsonDict["memberships"] as? NSArray {
                var circles: NSMutableDictionary = NSMutableDictionary()
                
                for membership in memberships {
                    if let circleName = membership["circleName"] as? String {
                        if let circleId = membership["circle"] as? String {
                            circles.setValue(circleName, forKey: circleId)
                        }
                    }
                }
                
                self.circles = circles
                defaults.setObject(circles, forKey: "circles")
            }
            
            if let name = jsonDict["name"] as? String {
                var profile = NSMutableDictionary()
                profile["name"] = name

                self.profile = profile
                defaults.setObject(profile, forKey: "profile")
            }
            
            defaults.synchronize()
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
            if let circles = self.circles {
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
                dest.baseUrl = self.baseUrl
                dest.session = self.session
                dest.profile = self.profile
                dest.managedObjectContext = self.managedObjectContext
                if let circles = circles {
                    for circle in circles {
                        var circleDict = NSMutableDictionary()
                        circleDict["name"] = circle.value
                        circleDict["id"] = circle.key
                        dest.circle = circleDict
                    }
                }
            }
            else {
                // toCirclesSegue
                let dest = segue.destinationViewController as! CirclesViewController
                dest.baseUrl = self.baseUrl
                dest.session = self.session
                dest.profile = self.profile
                dest.circles = self.circles
                dest.managedObjectContext = self.managedObjectContext
            }
        }
    }
    
    
    func configureView() {

    }

    func getUserDataAndSegue() {
        // See if we're already signed in to Circle Blvd. It's possible that our
        // session has been saved between runs. If /data/user returns success,
        // that means we can continue without entering a password.
        var request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/data/user")!)
        
        let dataTask = session.dataTaskWithRequest(request, completionHandler: {
            (data: NSData!, response:NSURLResponse!, error: NSError!) -> Void in
            if let response = response {
                let httpResponse = response as! NSHTTPURLResponse
                if (httpResponse.statusCode == 200) {
                    self.didSignIn(data)
                    self.toSegue()
                }
                else {
                    println("Server returned an error code")
                }
            }
            else {
                println("Could not access the Internet")
                // Onward! Load defaults from last successful signin
                self.profile = self.defaults.objectForKey("profile") as! NSDictionary?
                self.circles = self.defaults.objectForKey("circles") as! NSDictionary?
                
                self.toSegue()
            }
        })
        dataTask.resume()
    }
    
    override func viewDidAppear(animated: Bool) {
        // println("VOILA")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        self.getUserDataAndSegue()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}