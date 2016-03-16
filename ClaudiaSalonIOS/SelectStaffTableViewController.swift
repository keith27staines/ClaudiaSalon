//
//  SelectStaffTableViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 15/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class SelectStaffTableViewController : UITableViewController , NSFetchedResultsControllerDelegate {
    var selectedEmployee:Employee?
    var fetchedResultsController:NSFetchedResultsController!
    let moc = Coredata.sharedInstance.backgroundContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let fetch = NSFetchRequest(entityName: "Employee")
        fetch.predicate = NSPredicate(value: true) //NSPredicate(format: "isActive = %@", NSNumber(bool:true))
        let sort = NSSortDescriptor(key: "firstName", ascending: true)
        fetch.sortDescriptors = [sort]
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetch, managedObjectContext: self.moc, sectionNameKeyPath: nil, cacheName: nil)
        self.fetchedResultsController.delegate = self
        try! self.fetchedResultsController.performFetch()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let employee = self.selectedEmployee {
            if let indexPath = self.fetchedResultsController.indexPathForObject(employee) {
                self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Middle, animated: false)
            }
        }
    }
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        if let employee = self.fetchedResultsController.fetchedObjects?[indexPath.row] as? Employee {
                employee.managedObjectContext!.performBlockAndWait() {
                    cell.textLabel!.text = employee.firstName ?? ""
                    cell.detailTextLabel!.text = employee.lastName ?? ""
                    if employee.objectID == self.selectedEmployee?.objectID {
                        cell.accessoryType = .Checkmark
                    } else {
                        cell.accessoryType = .None
                    }
            }
        }
        return cell
    }
}
