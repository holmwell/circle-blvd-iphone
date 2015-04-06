//
//  DetailViewController.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 3/30/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, SessionViewProtocol {

    @IBAction func swipeRight(sender: UISwipeGestureRecognizer) {
        
    }
    
    @IBAction func unwindToMasterViewController(segue: UIStoryboardSegue) {
        //nothing goes here
    }
    
    @IBOutlet weak var renounceOwnershipButton: UIButton!
    
    @IBAction func renounceOwnership(sender: AnyObject) {
        if let task = detailItem as? Task {
            task.owner = ""
            saveTask(task)
            self.configureView()
        }
    }
    
    
    @IBOutlet weak var takeOwnershipButton: UIButton!
    
    @IBAction func takeOwnership(sender: UIButton) {
        if let profile = profile {
            if let profileName = profile["name"] as? String {
                if let task = detailItem as? Task {
                    task.owner = profileName
                    saveTask(task)
                    self.configureView()
                }
            }
        }
    }
    
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!

    @IBOutlet weak var ownerDecoration: UILabel!

    @IBOutlet weak var statusControl: UISegmentedControl!
 
    @IBAction func statusControlAction(sender: UISegmentedControl) {
    
        if let task = detailItem as? Task {
            switch sender.selectedSegmentIndex {
            case 0:
                task.status = "sad"
                break
            case 1:
                task.status = ""
                break
            case 2:
                task.status = "assigned"
                break
            case 3:
                task.status = "active"
                break
            case 4:
                task.status = "done"
                break
            default:
                task.status = ""
                break
            }
            
            saveTask(task)
        }
    }
    
    func valueOrEmptyString(optional: NSString?) -> NSString {
        if (optional? != nil) {
            return optional!
        }
        else {
            return ""
        }
    }
    
    func saveTask(task: Task) {
        func getSaveRequest(task: Task) -> NSURLRequest {
            var request = NSMutableURLRequest(URL: NSURL(string: self.baseUrl! + "/data/story")!)
            
            request.HTTPMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            var parameters = NSMutableDictionary()
            parameters["id"] = task.id
            parameters["summary"] = task.summary
            parameters["description"] = valueOrEmptyString(task.longDescription)
            parameters["owner"] = valueOrEmptyString(task.owner)
            parameters["status"] = valueOrEmptyString(task.status)
            parameters["projectId"] = task.circleId
            
            // pass dictionary to nsdata object and set it as request body
            var err: NSError?
            request.HTTPBody = NSJSONSerialization.dataWithJSONObject(parameters, options: nil, error: &err)
            
            return request
        }
        
        if let session = session {
            let request = getSaveRequest(task)
            
            let dataTask = session.dataTaskWithRequest(request, completionHandler: {
                (data: NSData!, response:NSURLResponse!, error: NSError!) -> Void in
                
                if let httpResponse = response as? NSHTTPURLResponse {
                    if (httpResponse.statusCode == 200) {
                        // TODO: Show success
                    }
                    else {
                        // TODO: Show error (invalid login)
                    }
                }
                else {
                    // Show error
                }
            })
            dataTask.resume()
        }
    }
    
    
    @IBOutlet weak var commentsDecoration: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    
    var numberOfComments = 0
    
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    var session: NSURLSession? = nil
    var baseUrl: String? = ""
    var profile: NSDictionary?
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail: AnyObject = self.detailItem {
            
            if let label = self.summaryLabel {
                label.text = detail.valueForKey("summary") as? String
            }
            
            if let label = self.ownerLabel {
                label.text = detail.valueForKey("owner") as? String
                if let ownerText = label.text {
                    if ownerText == "" {
                        ownerDecoration.hidden = true
                    }
                    else {
                        ownerDecoration.hidden = false
                    }
                }
                else {
                    ownerDecoration.hidden = true
                }
            }
            
            if let label = self.detailDescriptionLabel {
                label.text = detail.valueForKey("longDescription") as? String
            }
            
            if let control = self.statusControl {
                if let isMilepost = detail.valueForKey("isMilepost") as? Bool {
                    if (isMilepost) {
                        control.hidden = true
                        self.title = "Milepost"
                    }
                }
                if let isNextMeeting = detail.valueForKey("isNextMeeting") as? Bool {
                    if (isNextMeeting) {
                        control.hidden = true
                        self.title = ""
                    }
                }
                
                if let status = detail.valueForKey("status") as? String {
                    
                    switch status {
                        case "sad":
                            control.selectedSegmentIndex = 0
                            break
                        case "assigned":
                            control.selectedSegmentIndex = 2
                            break
                        case "active":
                            control.selectedSegmentIndex = 3
                            break
                        case "done":
                            control.selectedSegmentIndex = 4
                            break
                    default:
                        control.selectedSegmentIndex = 1
                        break
                    }
                }
                else {
                    control.selectedSegmentIndex = 1
                }
            }
            
            if let control = self.commentsLabel {
                if let comments = (detail as? Task)?.comments {
                    var allCommentsString = ""
                    comments.enumerateObjectsUsingBlock { (comment, index, stop) -> Void in
                        
                        let comment = comment as Comment
                        var commentString = ""
                        commentString += comment.authorName + ": "
                        commentString += comment.text
                        commentString += "\n"
                        
                        // prepend, to have comments show in
                        // reverse chronilogical order
                        allCommentsString = commentString + allCommentsString
                    }
                    control.text = allCommentsString
                    if allCommentsString == "" {
                        self.commentsDecoration?.hidden = true
                    }
                    else {
                        self.commentsDecoration?.hidden = false
                    }
                }
                else {
                    println("Comments not cast properly")
                }
            }
            
            if let control = self.takeOwnershipButton {
                if let profile = profile {
                    if let profileName = profile["name"] as? String {
                        if let task = detail as? Task {
                            if task.isTask() {
                                if let owner = task.owner {
                                    if (owner.compare("", options: NSStringCompareOptions.LiteralSearch) == NSComparisonResult.OrderedSame) {
                                        control.hidden = false
                                    }
                                    else {
                                        control.hidden = true
                                    }
                                }
                                else {
                                    control.hidden = false
                                }
                            }
                            else {
                                control.hidden = true
                            }
                            
                            self.renounceOwnershipButton?.hidden = !control.hidden
                        }
                    }
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

