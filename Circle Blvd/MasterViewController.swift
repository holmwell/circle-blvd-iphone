//
//  MasterViewController.swift
//  Circle Blvd
//
//  Created by Phil Manijak on 3/30/15.
//  Copyright (c) 2015 Secret Project LLC. All rights reserved.
//

import UIKit
import CoreData
import Foundation
import Argo

class MasterViewController: UIViewController, CircleViewProtocol {

    var session: NSURLSession?
    var baseUrl: String?

    var profile: NSDictionary?
    var managedObjectContext: NSManagedObjectContext?
    var circle: NSDictionary? 
    

    @IBAction func myTasksAction(sender: UIBarButtonItem) {
        if let tableView = actualTableView {
            tableView.viewFilter = CircleViewFilter.MyTasks
        }
    }
    
    @IBAction func allTasksAction(sender: UIBarButtonItem) {
        if let tableView = actualTableView {
            tableView.viewFilter = CircleViewFilter.AllTasks
        }
    }
    
    @IBOutlet weak var titleItem: UINavigationItem!
    
    @IBOutlet weak var actualTableView: CircleView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let tableView = actualTableView {
            // TODO: Check to make sure these values are set
            actualTableView.session = session
            actualTableView.baseUrl = baseUrl
            actualTableView.profile = profile
            actualTableView.managedObjectContext = managedObjectContext
            actualTableView.circle = circle
            
            // TODO: do we need to actualTableView.reloadData()?
            
            if let circle = circle {
                if let circleName = circle["name"] as String? {
                    self.title = circleName
                }
            }
        }
        
        // Do any additional setup after loading the view, typically from a nib.
//        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
//        self.navigationItem.rightBarButtonItem = addButton
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.actualTableView.indexPathForSelectedRow() {
                let object = self.actualTableView.fetchedResultsController.objectAtIndexPath(indexPath) as NSManagedObject
                let destination = segue.destinationViewController as DetailViewController
                destination.detailItem = object
                destination.baseUrl = self.baseUrl
                destination.session = self.session
                destination.profile = self.profile
            }
        }
    }
}

