//
//  ServiceCategoryTableViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 17/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class ServiceCategoryTableViewController : UITableViewController {
    var currentCategory:ServiceCategory? {
        didSet {
            Coredata.sharedInstance.backgroundContext.performBlockAndWait() {
                self._fetchController = nil
                self._fetchController = self.fetchController
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
    var _fetchController:NSFetchedResultsController?
    var categoryWasSelected:((selectedCategory:ServiceCategory)->Void)?
    var fetchController:NSFetchedResultsController {
        let moc = Coredata.sharedInstance.backgroundContext
        moc.performBlockAndWait() {
            if self._fetchController == nil {
                let fetchRequest = NSFetchRequest(entityName: "ServiceCategory")
                let parentCategory = self.currentCategory!
                fetchRequest.predicate = NSPredicate(format: "parent = %@", parentCategory)
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                self._fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
                try! self._fetchController?.performFetch()
            }
        }
        return _fetchController!
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    var subCategoriesCount:Int {
        var n:Int?
        Coredata.sharedInstance.backgroundContext.performBlockAndWait() {
            let sectionInfo = self.fetchController.sections![0]
            n = sectionInfo.numberOfObjects
        }
        return n!
    }
}

extension ServiceCategoryTableViewController {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var n:Int?
        Coredata.sharedInstance.backgroundContext.performBlockAndWait() {
            n = self.fetchController.sections?.count ?? 1
        }
        return n!
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var n:Int?
        Coredata.sharedInstance.backgroundContext.performBlockAndWait() {
            let sectionInfo = self.fetchController.sections![section]
            n = sectionInfo.numberOfObjects
        }
        return n!
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        self.configure(cell, indexPath: indexPath)
        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let moc = self.fetchController.managedObjectContext
        var newSelection:ServiceCategory?
        moc.performBlockAndWait() {
            newSelection = self.fetchController.objectAtIndexPath(indexPath) as? ServiceCategory
        }
        
        if let callback = self.categoryWasSelected, let newSelection = newSelection {
            callback(selectedCategory:newSelection)
        }
    }
    
    func configure(cell:UITableViewCell, indexPath:NSIndexPath) {
        Coredata.sharedInstance.backgroundContext.performBlockAndWait() {
            let category = self.fetchController.objectAtIndexPath(indexPath) as! ServiceCategory
            let name = category.name
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                cell.textLabel?.text = name
            }
        }
    }
}