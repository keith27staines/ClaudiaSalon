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
    lazy var importer:BQCloudImporter = {
        let importer = BQCloudImporter()
        importer.downloadWasUpdated = self.downloadInformationWasUpdated
        importer.downloadCompleted = self.downloadCompleted
        return importer
    }()
    let importTypes = CloudRecordType.typesAsArray()
    override func viewDidLoad() {
        self.tableView.reloadData()
    }
    func configureCell(cell:ImportInfoCell, indexPath:NSIndexPath) {
        let type = CloudRecordType.typesAsArray()[indexPath.row]
        let info = self.importer.downloads[type.rawValue]!
        cell.recordTypeLabel.text = info.recordType.rawValue
        cell.infoLabel.text = info.downloadStatus
        cell.activitySpinner.hidden = !info.executing
        cell.error = info.error
        if info.executing {
            cell.activitySpinner.startAnimating()
        } else {
            cell.activitySpinner.stopAnimating()
        }
    }
    func cancelImport() {
        self.importer.cancelImport()
    }
    func startImport() {
        self.importer.startImport()
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
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            
        }
        
    }
}

extension ImportTableViewController {
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.importer.downloads.count
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

