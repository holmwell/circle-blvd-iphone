//
//  CircleBlvdClient.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 5/3/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import Foundation

class CircleBlvdClient: SessionViewProtocol {
    
    @objc var baseUrl: String?
    @objc var profile: NSDictionary?
    @objc var circles: NSDictionary?
    
    @objc var session: NSURLSession? = NSURLSession.sharedSession()
    let defaults = NSUserDefaults.standardUserDefaults()
    
    init() {
        // baseUrl = "http://localhost:3000"
        baseUrl = "https://circleblvd.org"
        // baseUrl = "http://10.0.1.2:3000"
    }

    private func getSignInRequest(email: String, password: String) -> NSURLRequest {
        var request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl! + "/auth/signin")!)
        
        request.HTTPMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let bodyStr:String = "email=" + email + "&password=" + password
        request.HTTPBody = bodyStr.dataUsingEncoding(NSUTF8StringEncoding)
        
        return request
    }
    
    func signIn(email: String, password: String, callback: (err: Bool, result: String) -> Void) {
        let request = getSignInRequest(email, password: password)
        
        let dataTask = session!.dataTaskWithRequest(request, completionHandler: {
            (data: NSData!, response:NSURLResponse!, error: NSError!) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                if let httpResponse = response as? NSHTTPURLResponse {
                    if (httpResponse.statusCode == 200) {
                        // If we succeed, go ahead and populate our account data
                        self.getUserData {
                            err in
                            callback(err: err, result: "")
                        }
                    }
                    else {
                        callback(err: true, result: "Invalid login")
                    }
                }
                else {
                    callback(err: true, result: "No internet")
                }
            }
        })
        
        dataTask.resume()
    }
    
    // Takes the response from /data/user and saves it to our model
    private func didSignIn(userResponseData: NSData) {
        
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

    
    
    func getUserData(callback: (err: Bool) -> Void) {
        // See if we're already signed in to Circle Blvd. It's possible that our
        // session has been saved between runs. If /data/user returns success,
        // that means we can continue without entering a password.
        var request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl! + "/data/user")!)
        
        let dataTask = session!.dataTaskWithRequest(request, completionHandler: {
            (data: NSData!, response:NSURLResponse!, error: NSError!) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                if let response = response {
                    let httpResponse = response as! NSHTTPURLResponse
                    if (httpResponse.statusCode == 200) {
                        self.didSignIn(data)
                        callback(err: false)
                    }
                    else {
                        callback(err: true)
                    }
                }
                else {
                    println("Could not access the Internet")
                    // Onward! Load defaults from last successful signin
                    self.profile = self.defaults.objectForKey("profile") as! NSDictionary?
                    self.circles = self.defaults.objectForKey("circles") as! NSDictionary?
                    
                    println("Loading things from the cache. Running in offline mode.")
                    callback(err: false)
                }
            }
        })
        dataTask.resume()
    }


    
    func getCreateRequest(circleName: String, emailAddress: String, password: String, memberName: String) -> NSURLRequest {
        var request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl! + "/data/signup/now")!)
        
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        var parameters = NSMutableDictionary()
        parameters["circle"] = circleName
        parameters["name"] = memberName
        
        parameters["email"] = emailAddress
        parameters["password"] = password
        
        // pass dictionary to nsdata object and set it as request body
        var err: NSError?
        request.HTTPBody = NSJSONSerialization.dataWithJSONObject(parameters, options: nil, error: &err)
        
        return request
    }

}
