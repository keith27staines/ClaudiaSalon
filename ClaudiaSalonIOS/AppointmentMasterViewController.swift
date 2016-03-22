//
//  MasterViewController.swift
//  ClaudiaSalonIOS
//
//  Created by Keith Staines on 21/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    private var _fetchedResultsController: NSFetchedResultsController? = nil

    var appointmentViewController: AppointmentDetailViewController? = nil
    lazy var managedObjectContext: NSManagedObjectContext = Coredata.sharedInstance.backgroundContext

    lazy var salon:Salon = {
        let salon = Salon(moc: Coredata.sharedInstance.backgroundContext)
        return salon
    }()

    lazy var importController:BQCoredataImportController = {
        let importer = BQCoredataImportController()
        return importer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.appointmentViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? AppointmentDetailViewController
            self.tableView.rowHeight = UITableViewAutomaticDimension
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        guard let _ = Salon.defaultSalon(Coredata.sharedInstance.backgroundContext) else {
            self.performSegueWithIdentifier("GotoImportViewController", sender: self)
            return
        }
        //self.performSegueWithIdentifier("GotoImportViewController", sender: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        let context = self.fetchedResultsController.managedObjectContext
        context.performBlockAndWait() {
            let appointment = Appointment.newObjectWithMoc(context)
            appointment.customer = self.salon.anonymousCustomer
            appointment.sale?.customer = self.salon.anonymousCustomer
            appointment.appointmentDate = NSDate()
            appointment.bookedDuration = 30 * 60
            Coredata.sharedInstance.saveContext()
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
            let object = self.fetchedResultsController.objectAtIndexPath(indexPath)
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! AppointmentDetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
                controller.appointmentWasUpdated = self.appointmentWasUpdated
            }
        }
    }
    func appointmentWasUpdated(appointment:Appointment) {
        let indexPath = self.fetchedResultsController.indexPathForObject(appointment)
        let cell = self.tableView.cellForRowAtIndexPath(indexPath!)
        self.configureCell(cell!, atIndexPath: indexPath!)
    }
}

extension MasterViewController {
    // MARK: - Table View Data Source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var n:Int!
        self.fetchedResultsController.managedObjectContext.performBlockAndWait() {
            n = self.fetchedResultsController.sections?.count ?? 0
        }
        return n
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var n:Int!
        self.fetchedResultsController.managedObjectContext.performBlockAndWait() {
            let sectionInfo = self.fetchedResultsController.sections![section]
            n = sectionInfo.numberOfObjects
        }
        return n
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
            Coredata.sharedInstance.saveContext()
        }
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let appointmentCell = cell as? AppointmentViewCellTableViewCell else {
            preconditionFailure("Cell is not an AppointmentViewCellTableViewCell")
        }
        let moc = self.fetchedResultsController.managedObjectContext
        moc.performBlockAndWait() {
            let appointment = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Appointment
            appointmentCell.appointment = appointment
            appointmentCell.cloudSynchButtonTapped = { appointment in
                var hasChanges:Bool?
                var needsExport:Bool?
                Coredata.sharedInstance.backgroundContext.performBlockAndWait() {
                    hasChanges = appointment.bqHasClientChanges?.boolValue ?? false
                    needsExport = appointment.bqNeedsCoreDataExport?.boolValue ?? false
                }
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    if hasChanges! {
                        let alert = UIAlertController(title: "Synch changes?", message: "Tap 'Synch' if you are ready to synch this appointment with the cloud", preferredStyle: .ActionSheet)
                        let exportAction = UIAlertAction(title: "Synch", style: .Default) { action in
                            
                        }
                        let cancelAction = UIAlertAction(title: "Not yet", style: .Cancel) { action in
                            
                        }
                        alert.addAction(exportAction)
                        alert.addAction(cancelAction)
                        self.presentViewController(alert, animated: true, completion: nil)
                    } else if needsExport! {
                        let alert = UIAlertController(title: "Synching", message: "This appointment's changes are being synchronized to the cloud", preferredStyle: .ActionSheet)
                        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                        alert.addAction(okAction)
                        self.presentViewController(alert, animated: true, completion: nil)
                    } else {
                        let alert = UIAlertController(title: "Already Synched", message: "This appointment has been synchronized with the cloud", preferredStyle: .ActionSheet)
                        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                        alert.addAction(okAction)
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                }

            }
        }
    }
}

extension MasterViewController {
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Appointment", inManagedObjectContext: self.managedObjectContext)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "appointmentDate", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "Master")
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
        do {
            try _fetchedResultsController!.performFetch()
        } catch {
            fatalError("Unresolved error \(error)")
        }
        
        return _fetchedResultsController!
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            self.tableView.beginUpdates()
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            switch type {
            case .Insert:
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                if let cell = self.tableView.cellForRowAtIndexPath(indexPath!) {
                    self.configureCell(cell, atIndexPath: indexPath!)
                }
            case .Move:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            }
        }
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            self.tableView.endUpdates()
        }
    }
    
    /*
    // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
    // In the simplest, most efficient, case, reload the table view.
    self.tableView.reloadData()
    }
    */
}
