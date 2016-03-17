//
//  ServiceCategoryTableViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 17/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit


class ServiceCategoryTableViewController : UITableViewController {
    var currentCategory:ServiceCategory?
    var _fetchController:NSFetchedResultsController?
    var fetchController:NSFetchedResultsController {
        if _fetchController == nil {
            let fetchRequest = NSFetchRequest(entityName: "ServiceCategory")
            let parentCategory = self.currentCategory!.parent!
            fetchRequest.predicate = NSPredicate(format: "parent = %@", parentCategory)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            _fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Coredata.sharedInstance.backgroundContext, sectionNameKeyPath: nil, cacheName: nil)
            try! _fetchController?.performFetch()
        }
        return _fetchController!
    }
}

extension ServiceCategoryTableViewController {
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
        let category = self.fetchController.objectAtIndexPath(indexPath) as! ServiceCategory
        let moc = category.managedObjectContext!
        moc.performBlockAndWait() {
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = category.name
        }
        
    }
}