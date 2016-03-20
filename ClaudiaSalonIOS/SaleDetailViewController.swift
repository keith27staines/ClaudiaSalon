//
//  SaleDetailViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 02/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//


import UIKit
import CoreData



class SaleDetailViewController: UITableViewController, NSFetchedResultsControllerDelegate, SaleItemUpdateReceiver {
    var delegate:SaleItemUpdateReceiver?
    var saleItemBeingEdited:SaleItem?
    var saleID:NSManagedObjectID! {
        didSet {
            self._sale = nil
        }
    }
    private var _fetchedResultsController: NSFetchedResultsController? = nil
    lazy var managedObjectContext: NSManagedObjectContext = Coredata.sharedInstance.backgroundContext
    var _sale:Sale?
    var sale:Sale {
        if self._sale == nil {
            let moc = self.managedObjectContext
            moc.performBlockAndWait() {
                self._sale = moc.objectWithID(self.saleID) as? Sale
            }
            self.tableView.reloadData()
        }
       return _sale!
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    override func viewWillAppear(animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
        super.viewWillAppear(animated)
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func insertNewObject(sender: AnyObject) {
        let context = self.fetchedResultsController.managedObjectContext
        context.performBlockAndWait() {
            let saleItem = SaleItem.newObjectWithMoc(context)
            saleItem.sale = self.sale
        }
    }
    func employeeInfoButtonTapped(cell: SaleDetailCellTableViewCell) {
        self.performSegueWithIdentifier("GotoSelectEmployee", sender: cell)
        
    }
    func serviceInfoButtonTapped(cell: SaleDetailCellTableViewCell) {
        self.performSegueWithIdentifier("GotoSelectService", sender: cell)
    }
    func saleItemWasUpdated(saleItem: SaleItem) {
        self.delegate?.saleItemWasUpdated(saleItem)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! SaleDetailCellTableViewCell
        if segue.identifier == "GotoSelectEmployee" {
            let vc = segue.destinationViewController as! SelectStaffTableViewController
            saleItemBeingEdited = cell.saleItem
            vc.selectedEmployee = saleItemBeingEdited!.performedBy
            vc.employeeWasSelected = self.employeeWasChanged
        }
        if segue.identifier == "GotoSelectService" {
            let vc = segue.destinationViewController as! SelectServiceViewController
            saleItemBeingEdited = cell.saleItem
            vc.currentCategory = saleItemBeingEdited?.service?.serviceCategory
            vc.originalService = saleItemBeingEdited!.service
            vc.selectedService = saleItemBeingEdited!.service
            vc.serviceWasSelected = self.serviceWasChanged
        }

    }
    func serviceWasChanged(selectedService:Service) {
        var indexPath:NSIndexPath?
        self.saleItemBeingEdited?.managedObjectContext?.performBlockAndWait() {
            let saleItem = self.saleItemBeingEdited!
            saleItem.service = selectedService
            saleItem.minimumCharge = selectedService.minimumCharge
            saleItem.maximumCharge = selectedService.maximumCharge
            saleItem.nominalCharge = selectedService.nominalCharge
            saleItem.updatePrice()
            indexPath = self.fetchedResultsController.indexPathForObject(saleItem)!
        }
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            if let cell = self.tableView.cellForRowAtIndexPath(indexPath!) {
                self.configureCell(cell, atIndexPath: indexPath!)
            }
        }
    }
    func employeeWasChanged(selectedEmployee:Employee) {
        selectedEmployee.managedObjectContext?.performBlockAndWait() {
            self.saleItemBeingEdited!.performedBy = selectedEmployee
        }
    }
}

extension SaleDetailViewController {
    // MARK: - Table View Data Source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell:UITableViewCell, atIndexPath:NSIndexPath) {
    
        guard let cell = cell as? SaleDetailCellTableViewCell else {
            return
        }
        guard let saleItem = self.fetchedResultsController.objectAtIndexPath(atIndexPath) as? SaleItem else {
            return
        }
        cell.delegate = self
        cell.employeeInfoBlock = self.employeeInfoButtonTapped
        cell.serviceInfoBlock = self.serviceInfoButtonTapped
        cell.updateWithSaleItem(saleItem)
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
        return 224
    }

}

extension SaleDetailViewController {
    // MARK: - Fetched results controller
    
    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        let entity = NSEntityDescription.entityForName("SaleItem", inManagedObjectContext: self.managedObjectContext)
        fetchRequest.entity = entity
        let predicate = NSPredicate(format: "sale = %@", self.saleID)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "createdDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]

        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
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
