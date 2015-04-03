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
    
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let session = NSURLSession.sharedSession()
    let baseUrl = "https://circleblvd.org"
    var isSignedIn = false
    
    var userData: NSData?
    var circles: NSDictionary?
    
    @IBAction func signInButton(sender: AnyObject) {
        if let pass = self.passwordTextField {
            if let email = self.emailTextField {
                
                let url = NSURL(string: self.baseUrl)
                var request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/auth/signin")!)
                
                request.HTTPMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                
                let bodyStr:String = "email=" + email.text + "&password=" + pass.text
                request.HTTPBody = bodyStr.dataUsingEncoding(NSUTF8StringEncoding)
                
                let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data: NSData!, response:NSURLResponse!,
                    error: NSError!) -> Void in
                    //do something
                    let httpResponse = response as NSHTTPURLResponse
                    if (httpResponse.statusCode == 200) {
                        var request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/data/user")!)
                        let userTask = self.session.dataTaskWithRequest(request, completionHandler: { (data: NSData!, response:NSURLResponse!,
                            error: NSError!) -> Void in
                            //do something
                            let httpResponse = response as NSHTTPURLResponse
                            if (httpResponse.statusCode == 200) {
                                println("signed in")
                                self.didSignIn(data)
                                self.toSegue()
                            }
                            else {
                                // TODO: Show error (network failed)
                            }
                        })
                        userTask.resume()
                    }
                    else {
                        // TODO: Show error (invalid login)
                    }
                })
                
                dataTask.resume()
            }
        }
    }
    
    func didSignIn(userResponseData: NSData) {
        
        let json: AnyObject? = NSJSONSerialization.JSONObjectWithData(userResponseData, options: NSJSONReadingOptions(0), error: nil)
        var jsonDict: NSDictionary = json as NSDictionary
        
        var memberships = jsonDict["memberships"] as NSArray
        var circles: NSMutableDictionary = NSMutableDictionary()
        for membership in memberships {
            
            if let circleName: AnyObject = membership["circleName"] {
                if let circleId: AnyObject = membership["circle"] {
                    circles.setValue(circleName as String, forKey: circleId as String)
                }
            }
        }

//        if (circles.count == 1) {
//            self.performSegueWithIdentifier("toMasterSegue", sender: self)
//        }
        
        self.circles = circles
        println(circles)
    }
    
    func toSegue() {
        println("Onward!")
        dispatch_async(dispatch_get_main_queue()) {
            self.performSegueWithIdentifier("toCirclesSegue", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if let segueName = segue.identifier {
            if segueName == "toMasterSegue" {
                let dest = segue.destinationViewController as MasterViewController
                dest.baseUrl = self.baseUrl
                dest.session = self.session
                dest.managedObjectContext = self.managedObjectContext
            }
            else {
                println("Prepping ...")
                let dest = segue.destinationViewController as CirclesViewController
                dest.baseUrl = self.baseUrl
                dest.session = self.session
                dest.circles = self.circles
                dest.managedObjectContext = self.managedObjectContext
            }
        }
    }
    
    
    func configureView() {

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.view.hidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        
        var request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl + "/data/user")!)
        let dataTask = session.dataTaskWithRequest(request, completionHandler: { (data: NSData!, response:NSURLResponse!,
            error: NSError!) -> Void in
            //do something
            let httpResponse = response as NSHTTPURLResponse
            if (httpResponse.statusCode == 200) {
                println("already signed in")
                // TODO: There's no way this will work in the real world
//                self.userData = data
                self.didSignIn(data)
                self.toSegue()
            }
            else {
                println(httpResponse)
            }
        })
        dataTask.resume()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}