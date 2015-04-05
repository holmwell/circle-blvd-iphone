import UIKit
import CoreData
import Foundation

// TODO: Learning how to use instances ...
class MasterViewController2: UIViewController, CircleViewProtocol {
    
    var session: NSURLSession?
    var baseUrl: String?
    
    var profile: NSDictionary?
    var managedObjectContext: NSManagedObjectContext?
    var circle: NSDictionary?
    
    
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
            
            actualTableView.reloadData()
            // didGetCircle()
        }
        
        // Do any additional setup after loading the view, typically from a nib.
        //        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        //        self.navigationItem.rightBarButtonItem = addButton
        // didGetCircle()
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //    func insertTask(task: NSDictionary) {
    //        let context = self.fetchedResultsController.managedObjectContext
    //        let entity = self.fetchedResultsController.fetchRequest.entity!
    //
    //        let newManagedObject = NSEntityDescription.insertNewObjectForEntityForName(entity.name!, inManagedObjectContext: context) as NSManagedObject
    //
    //        // If appropriate, configure the new managed object.
    //        // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    //        copyTask(task, destination: newManagedObject);
    //    }
    
    
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

