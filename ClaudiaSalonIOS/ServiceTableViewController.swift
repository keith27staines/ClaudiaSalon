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
            if let f = _fetchController {
                let m = f.managedObjectContext
                m.performBlockAndWait() {
                    self._fetchController = nil
                    let _ = self.fetchController
                    self.tableView.reloadData()
                }
            }
        }
    }
    var selectedService:Service?
    var serviceWasSelected:((selectedService:Service)->Void)?
    
    var _fetchController:NSFetchedResultsController?
    var fetchController:NSFetchedResultsController {
        if _fetchController == nil {
            let fetchRequest = NSFetchRequest(entityName: "Service")
            fetchRequest.predicate = NSPredicate(format: "serviceCategory = %@", self.category)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            _fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Coredata.sharedInstance.backgroundContext, sectionNameKeyPath: nil, cacheName: nil)
            try! _fetchController?.performFetch()
        }
        return _fetchController!
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
    func configure(cell:UITableViewCell, indexPath:NSIndexPath) {
        let service = self.fetchController.objectAtIndexPath(indexPath) as! Service
        let moc = service.managedObjectContext!
        moc.performBlockAndWait() {
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = service.name
            if service.objectID == self.selectedService?.objectID {
                cell.accessoryType = .Checkmark
            } else {
                cell.accessoryType = .None
            }
        }
    }
}