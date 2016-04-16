//
//  ImportTableViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 10/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit
import CloudKit
import CoreData

class ImportTableViewController : UITableViewController {
    
    var bulkImportCompletionBlock:(()->Void)?
    var salonName = "?"
    
    lazy var importer:BQCloudImporter? = {
        let importer = Coredata.sharedInstance.importController
        return Coredata.sharedInstance.importController
    }()
    let importTypes = CloudRecordType.typesAsArray()
    override func viewDidLoad() {
        self.tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let alert = UIAlertController(title: "Data Download Required", message: "To finish setting up \(salonName) we need to download its data from the cloud", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Download", style: .Default, handler: { (download) in
            self.startImport()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (cancel) in
            if let callback = self.bulkImportCompletionBlock {
                callback()
            }
        }))
        self.presentViewController(alert, animated: true) {}
    }
    func configureCell(cell:ImportInfoCell, indexPath:NSIndexPath) {
        let type = CloudRecordType.typesAsArray()[indexPath.row]
        let info = self.importer!.downloads[type.rawValue]!
        cell.recordTypeLabel.text = info.recordType.rawValue
        cell.infoLabel.text = info.downloadStatus
        cell.activitySpinner.hidden = !info.executing
        cell.error = info.error
        if info.executing {
            cell.activitySpinner.hidesWhenStopped = true
            cell.activitySpinner.hidden = false
            cell.activitySpinner.startAnimating()
        } else {
            cell.activitySpinner.stopAnimating()
        }
    }
    func cancelImport() {
        self.importer?.cancelImport()
    }
    func startImport() {
        self.importer?.downloadWasUpdated = self.downloadInformationWasUpdated
        self.importer?.downloadWasUpdated = self.downloadCompleted
        self.importer?.allDownloadsComplete = self.handleAllDownloadsComplete
        self.importer?.startImport()
    }
    func downloadInformationWasUpdated(info:DownloadInfo) {
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            let type = info.recordType
            let row = CloudRecordType.indexForType(type)
            let indexPath = NSIndexPath(forItem: row, inSection: 0)
            if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? ImportInfoCell {
                self.configureCell(cell, indexPath: indexPath)
            }
        }
    }
    func downloadCompleted(info:DownloadInfo) {
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            self.downloadInformationWasUpdated(info)
        }
    }
    func handleAllDownloadsComplete(withErrors:[NSError]?) {
        let alert = UIAlertController(title: "Download completed", message: "\(salonName) is now ready for use on this device", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .Default, handler: { (download) in
            print("download finished")
            if let callback = self.bulkImportCompletionBlock {
                callback()
            }
        }))
        self.presentViewController(alert, animated: true) {}
    }
}

extension ImportTableViewController {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let importer = self.importer {
            return importer.downloads.count ?? 0
        } else {
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as! ImportInfoCell
        self.configureCell(cell, indexPath: indexPath)
        return cell
    }
    override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? ImportInfoCell {
            cell.activitySpinner.stopAnimating()
        }
    }
}

