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
    
    var employeeWasSelected:((selectedEmployee:Employee)->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let fetch = NSFetchRequest(entityName: "Employee")
        fetch.predicate = NSPredicate(value: true) //NSPredicate(format: "isActive = %@", NSNumber(bool:true))
        let sort = NSSortDescriptor(key: "firstName", ascending: true)
        fetch.sortDescriptors = [sort]
        let moc = Coredata.sharedInstance.managedObjectContext
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetch, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let employee = self.fetchedResultsController.fetchedObjects?[indexPath.row] as? Employee else {
            fatalError("User tapped a row with index path not associated with an employee")
        }
        
        // Deselect the previously selected employee (if there is one)
        if let oldEmployee = self.selectedEmployee {
            if oldEmployee == employee {
                return // Nothing to do - user tapped the already selected row
            }
            guard let oldIndexPath = self.fetchedResultsController.indexPathForObject(oldEmployee) else {
                fatalError("Currently selected employee is not in the table")
            }
            if let cell = tableView.cellForRowAtIndexPath(oldIndexPath) as UITableViewCell? {
                self.selectedEmployee = nil
                cell.accessoryType = .None
            }
        }
        
        // Select the tapped employee
        self.selectedEmployee = employee
        if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            cell.accessoryType = .Checkmark
            if let callback = self.employeeWasSelected {
                callback(selectedEmployee:employee)
            }
        }
    }
}
