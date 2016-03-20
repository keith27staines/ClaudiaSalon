//
//  ServiceTableViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 17/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class ServiceTableViewController : UITableViewController {
    var category:ServiceCategory! {
        didSet {
            let moc = Coredata.sharedInstance.backgroundContext
            moc.performBlockAndWait() {
                if let f = self._fetchController {
                    self._fetchController = nil
                    let _ = self.fetchController
                }
            }
        }
    }
    func reloadData() {
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            if let tableView = self.tableView {
                tableView.reloadData()
            }
        }
    }
    var selectedService:Service?
    var serviceWasSelected:((selectedService:Service)->Void)?
    var servicesCount:Int {
        let sectionInfo = self.fetchController.sections![0]
        return sectionInfo.numberOfObjects
    }
    
    private var _fetchController:NSFetchedResultsController?
    var fetchController:NSFetchedResultsController {
        if _fetchController == nil {
            let moc = Coredata.sharedInstance.backgroundContext
            moc.performBlockAndWait() {
                let fetchRequest = NSFetchRequest(entityName: "Service")
                fetchRequest.predicate = NSPredicate(format: "serviceCategory = %@", self.category)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                self._fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
                try! self._fetchController?.performFetch()
            }
        }
        return _fetchController!
    }
    override func viewDidLoad() {
        self.tableView.reloadData()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
        if let service = self.selectedService {
            if let indexPath = self.fetchController.indexPathForObject(service) {
                self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Middle, animated: true)
            }
        }
    }
}

extension ServiceTableViewController {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchController.sections?.count ?? 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchController.sections![section]
        return sectionInfo.numberOfObjects
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        self.configure(cell, indexPath: indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var previousIndexPath:NSIndexPath?
        if let oldService = self.selectedService {
            let moc = oldService.managedObjectContext
            moc!.performBlockAndWait() {
                previousIndexPath = self.fetchController.indexPathForObject(oldService)
                self.selectedService = self.fetchController.objectAtIndexPath(indexPath) as? Service
            }
        }
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            if let previousIndexPath = previousIndexPath {
                let oldCell = self.tableView.cellForRowAtIndexPath(previousIndexPath)
                oldCell?.accessoryType = .None
            }
            let selectedCell = self.tableView.cellForRowAtIndexPath(indexPath)
            selectedCell?.accessoryType = .Checkmark
            if let callBack = self.serviceWasSelected {
                callBack(selectedService: self.selectedService!)
            }
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    func configure(cell:UITableViewCell, indexPath:NSIndexPath) {
        let service = self.fetchController.objectAtIndexPath(indexPath) as! Service
        let moc = service.managedObjectContext!
        moc.performBlockAndWait() {
            let chargeInfo = "Min £\(service.minimumCharge!) | Nominal £\(service.nominalCharge!) | Max £\(service.maximumCharge!)"
            let name = service.name
            let isSelectedService = (service.objectID == self.selectedService?.objectID)
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                cell.textLabel?.text = name
                cell.detailTextLabel?.text = chargeInfo
                if isSelectedService {
                    cell.accessoryType = .Checkmark
                } else {
                    cell.accessoryType = .None
                }
            }
        }
    }
}


























