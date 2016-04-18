//
//  MasterViewController.swift
//  ClaudiaSalonIOS
//
//  Created by Keith Staines on 21/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit
import CoreData
import CloudKit


class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    static var onceOnlyFlag:dispatch_once_t = 0

    private var _fetchedResultsController: NSFetchedResultsController? = nil
    
    private var currentSalonName:String? = nil
    var appointmentViewController: AppointmentDetailViewController? = nil
    lazy var moc: NSManagedObjectContext = Coredata.sharedInstance.managedObjectContext

    lazy var salon:Salon = {
        let salon = Salon(moc: self.moc)
        return salon
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(MasterViewController.insertNewObject(_:)))
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.appointmentViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? AppointmentDetailViewController
            self.tableView.rowHeight = UITableViewAutomaticDimension
        }
        
        let menuButtonImage = UIImage(named: "MenuButton")
        let menuButton = UIBarButtonItem(image: menuButtonImage, style: .Plain, target: self, action: #selector(MasterViewController.showMenu(_:)))
        self.navigationItem.leftBarButtonItem = menuButton
        
    }
    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Do we have a default salon?
        guard let _ = AppDelegate.defaultSalonKey() else {
            // No, so ask the user to add one
            self.performSegueWithIdentifier("GotoAddSalon", sender: self)
            AppDelegate.setProcessCloudNotifications(false)
            AppDelegate.setExportChangesToCloud(false)
            return
        }
        self.loadDefaultSalon()
    }
    
    func loadDefaultSalon() {
        guard let salonRecordName = AppDelegate.defaultSalonKey() else {
            return
        }

        let coredata = self.openCoredataSalon(salonRecordName)
        Coredata.setSharedInstance(salonRecordName)
        
        // Have we downloaded any data from the cloud for this salon?
        guard let _ = Salon.defaultSalon(coredata.managedObjectContext) else {
            dispatch_once(&MasterViewController.onceOnlyFlag) {
                self.performSegueWithIdentifier("GotoImportViewController", sender: self)
            }
            return
        }
        
        // Decide whether to start processing cloud notifications and exporting changes to the cloud
        let cloudUpdating = AppDelegate.appStartsWithCloudUpdating()
        AppDelegate.setProcessCloudNotifications(cloudUpdating)
        AppDelegate.setExportChangesToCloud(cloudUpdating)
        let exportController = Coredata.sharedInstance.exportController
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MasterViewController.appointmentWasExported(_:)), name: "appointmentWasExported", object: exportController)
        
        if AppDelegate.exportChangesToCloud() {
            Coredata.sharedInstance.exportController.startExportIterations()
        }
        
        let processCloudNotifications = AppDelegate.processCloudNotifications()
        Coredata.sharedInstance.importController?.cloudNotificationProcessor.willProcessNotifications = processCloudNotifications
        self.tableView.reloadData()
    }
    
    func openCoredataSalon(recordName:String) -> Coredata {
        let coredata = Coredata.coredataForKey(recordName)
        let _ = coredata.importController
        return coredata
    }
    
    func showMenu(sender:AnyObject?) {
        self.performSegueWithIdentifier("showMenu", sender: self)
    }
    
    func appointmentWasExported(notification:NSNotification) {
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            guard let userInfo = notification.userInfo else {
                assertionFailure("expected a userInfo object from the appointmentWasExported notification but none was provided")
                return
            }
            if let error = userInfo["error"] as? NSError {
                assertionFailure("unexpected error after exporting appointment \(error)")
                return
            }
            guard let ckRecord = userInfo["record"] as? CKRecord else {
                assertionFailure("expected the userInfo object from the appointmentWasExported notification to contain a CKRecord")
                return
            }
            let recordID = ckRecord.recordID.recordName
            guard let appointment = Appointment.fetchForCloudID(recordID, moc: self.moc) else {
                assertionFailure("expected to find a coredata appointment with icloud id = \(recordID)")
                return
            }
            guard let indexPath = self.fetchedResultsController.indexPathForObject(appointment) else {
                assertionFailure("The fetched results controller didn't return an index path for the appointment")
                return
            }
            if let cell = self.tableView.cellForRowAtIndexPath(indexPath) {
                self.configureCell(cell, atIndexPath: indexPath)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        let appointment = Appointment.newObjectWithMoc(self.moc)
        appointment.customer = self.salon.anonymousCustomer
        appointment.sale?.customer = self.salon.anonymousCustomer
        appointment.appointmentDate = NSDate()
        appointment.bookedDuration = 30 * 60
        try! self.moc.save()
        if let indexPath = self.fetchedResultsController.indexPathForObject(appointment) {
            self.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Middle)
        }
    }
    
    func cancelAppointmentAtIndexPath(indexPath:NSIndexPath) {
        if let appointment = self.fetchedResultsController.objectAtIndexPath(indexPath) as? Appointment {
            appointment.cancelled = true
            self.makeAppointmentReadyForExport(appointment)
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        
        let cancelAppointmentAction = UITableViewRowAction(style: .Normal, title: "Cancel Appointment") { (rowAction:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            self.cancelAppointmentAtIndexPath(indexPath)
        }
        cancelAppointmentAction.backgroundColor = UIColor.blueColor()
        
        return [cancelAppointmentAction]
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
            return
        }
        if segue.identifier == "showMenu" {
            return
        }
        if segue.identifier == "GotoImportViewController" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! ImportViewController
            controller.salonName = self.currentSalonName ?? "New Salon"
            controller.bulkImportCompletionBlock = {
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    self.dismissViewControllerAnimated(true, completion: nil)
                    self.tableView.reloadData()
                }
            }
            return
        }
        if segue.identifier == "GotoAddSalon" {
            let controller = segue.destinationViewController as! AddSalonController
            controller.completion = {controller in
                if let salonRecordName = controller.salonRecordName {
                    self.currentSalonName = controller.salonName
                    AppDelegate.addSalonKey(salonRecordName)
                    AppDelegate.setDefaultSalonKey(salonRecordName)
                }
            }
            return
        }
    }
    
    func appointmentWasUpdated(appointment:Appointment) {
        let indexPath = self.fetchedResultsController.indexPathForObject(appointment)
        let cell = self.tableView.cellForRowAtIndexPath(indexPath!)
        self.configureCell(cell!, atIndexPath: indexPath!)
    }
    
    func makeAppointmentReadyForExport(appointment:Appointment) {
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            appointment.bqHasClientChanges = false
            appointment.bqNeedsCoreDataExport = true
            appointment.sale?.bqHasClientChanges = false
            appointment.sale?.bqNeedsCoreDataExport = true
            if let saleItems = appointment.sale?.saleItem {
                for saleItem in saleItems {
                    saleItem.bqHasClientChanges = false
                    saleItem.bqNeedsCloudImport = false
                    saleItem.bqNeedsCoreDataExport = true
                }
            }
            Coredata.sharedInstance.save()
        }
    }
}

extension MasterViewController {
    // MARK: - Table View Data Source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let _ = Coredata.sharedInstance {
            let n = self.fetchedResultsController.sections?.count ?? 0
            return n
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        let n = sectionInfo.numberOfObjects
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
            Coredata.sharedInstance.save()
        }
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        guard let appointmentCell = cell as? AppointmentViewCellTableViewCell else {
            preconditionFailure("Cell is not an AppointmentViewCellTableViewCell")
        }
        
        let appointment = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Appointment
        appointmentCell.appointment = appointment
        
        appointmentCell.cloudSynchButtonTapped = { appointment, button in
            
            let hasChanges = appointment.bqHasClientChanges?.boolValue ?? false
            let needsExport = appointment.bqNeedsCoreDataExport?.boolValue ?? false
            
            var alert: UIAlertController!
            if hasChanges {
                alert = UIAlertController(title: "Synch changes?", message: "Tap 'Synch' if you are ready to synch this appointment with the cloud", preferredStyle: .ActionSheet)
                let exportAction = UIAlertAction(title: "Synch", style: .Default) { action in
                    self.makeAppointmentReadyForExport(appointment)
                }
                let cancelAction = UIAlertAction(title: "Not yet", style: .Cancel) { action in
                    
                }
                alert.addAction(exportAction)
                alert.addAction(cancelAction)
            } else if needsExport {
                alert = UIAlertController(title: "Synching", message: "This appointment's changes are waiting to be synchronized to the cloud", preferredStyle: .ActionSheet)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alert.addAction(okAction)
            } else {
                alert = UIAlertController(title: "Already Synched", message: "This appointment has been synchronized with the cloud", preferredStyle: .ActionSheet)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alert.addAction(okAction)
            }
            let popController = alert.popoverPresentationController
            popController?.sourceView = button
            popController?.sourceRect = button.bounds
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
}

extension MasterViewController {
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        let moc = Coredata.sharedInstance.managedObjectContext
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Appointment", inManagedObjectContext: moc)
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Predicate
        let predicate = NSPredicate(format: "cancelled == %@", false)
        
        fetchRequest.predicate = predicate
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "appointmentDate", ascending: false)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
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
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        default:
            return
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
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
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    /*
    // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
    // In the simplest, most efficient, case, reload the table view.
    self.tableView.reloadData()
    }
    */
}
