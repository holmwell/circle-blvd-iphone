//
//  DetailViewController.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 3/30/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!

    @IBOutlet weak var ownerDecoration: UILabel!

    @IBOutlet weak var statusControl: UISegmentedControl!
 
    @IBOutlet weak var commentsDecoration: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    
    var numberOfComments = 0
    
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

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
                    var commentString = ""
                    comments.enumerateObjectsUsingBlock { (comment, index, stop) -> Void in
                        
                        let comment = comment as Comment
                        commentString += comment.authorName + ": "
                        commentString += comment.text
                        commentString += "\n"
                    }
                    control.text = commentString
                    if commentString == "" {
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

