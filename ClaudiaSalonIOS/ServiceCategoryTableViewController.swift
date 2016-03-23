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
            self._fetchController = nil
            self._fetchController = self.fetchController
        }
    }
    func reloadData() {
        if let tableView = self.tableView {
            tableView.reloadData()
        }
    }
    var _fetchController:NSFetchedResultsController?
    var categoryWasSelected:((selectedCategory:ServiceCategory)->Void)?
    var fetchController:NSFetchedResultsController {
        if self._fetchController == nil {
            let fetchRequest = NSFetchRequest(entityName: "ServiceCategory")
            let parentCategory = self.currentCategory!
            fetchRequest.predicate = NSPredicate(format: "parent = %@", parentCategory)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            let moc = Coredata.sharedInstance.managedObjectContext
            self._fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
            try! self._fetchController?.performFetch()
        }
        return _fetchController!
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }
    var subCategoriesCount:Int {
        let sectionInfo = self.fetchController.sections![0]
        let n = sectionInfo.numberOfObjects
        return n
    }
}

extension ServiceCategoryTableViewController {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let n = self.fetchController.sections?.count ?? 1
        return n
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchController.sections![section]
        let n = sectionInfo.numberOfObjects
        return n
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")!
        self.configure(cell, indexPath: indexPath)
        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let newSelection = self.fetchController.objectAtIndexPath(indexPath) as? ServiceCategory
        if let callback = self.categoryWasSelected, let newSelection = newSelection {
            callback(selectedCategory:newSelection)
        }
    }
    
    func configure(cell:UITableViewCell, indexPath:NSIndexPath) {
        let category = self.fetchController.objectAtIndexPath(indexPath) as! ServiceCategory
        let name = category.name
        cell.textLabel?.text = name
    }
}






















