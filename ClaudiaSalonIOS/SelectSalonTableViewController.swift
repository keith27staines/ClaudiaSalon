//
//  SelectSalonTableViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 15/04/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit
import CloudKit

class SelectSalonTableViewController: UITableViewController {
    
    var salonKeys:[String] { return AppDelegate.salonKeys() }
    var defaultSalonRecordName:String? { return AppDelegate.defaultSalonKey() }
    var salonRecordsDictionary = [String:CKRecord]()
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GotoAddSalon" {
            let vc = segue.destinationViewController as! AddSalonController
            vc.completion = { vc in
                if let newSalonRecordName = vc.salonRecordName {
                    AppDelegate.addSalonKey(newSalonRecordName)
                    if AppDelegate.defaultSalonKey() == nil {
                        AppDelegate.setDefaultSalonKey(newSalonRecordName)
                    }
                    self.tableView.reloadData()
                }
            }
            vc.allowCancel = true
            return
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return salonKeys.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell") as! SalonTableViewCell
        self.configureCellAtIndexPath(cell, indexPath: indexPath)
        return cell
    }
    
    func configureCellAtIndexPath(cell:SalonTableViewCell,indexPath:NSIndexPath) -> SalonTableViewCell {
        let recordName = self.recordNameForIndexPath(indexPath)
        if let record = self.recordForIndexPath(indexPath) {
            cell.configureWithRecord(record)
        } else {
            cell.configureWithRecordName(recordName)
            fetchSalonFromCloud(recordName)
        }
        if recordName == self.defaultSalonRecordName {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let defaultSalonRecordName = self.defaultSalonRecordName {
            let row = self.salonKeys.indexOf(defaultSalonRecordName)!
            let oldCheckedCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0))
            oldCheckedCell?.accessoryType = .None
        }
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = .Checkmark
        let newDefaultRecord = self.recordForIndexPath(indexPath)
        AppDelegate.setDefaultSalonKey(newDefaultRecord?.recordID.recordName)
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
    }
    
    func configureCellAtIndexPath(indexPath:NSIndexPath) -> SalonTableViewCell {
        let configuredCell = tableView.cellForRowAtIndexPath(indexPath) as! SalonTableViewCell
        self.configureCellAtIndexPath(configuredCell, indexPath: indexPath)
        return configuredCell
    }
    
    func recordNameForIndexPath(indexPath:NSIndexPath) -> String {
        return salonKeys[indexPath.row]
    }
    
    func recordForIndexPath(indexPath:NSIndexPath) -> CKRecord? {
        let recordName = self.recordNameForIndexPath(indexPath)
        return self.salonRecordsDictionary[recordName]
    }
    
    func indexPathForRecordName(recordName:String) -> NSIndexPath? {
        guard let row = self.salonKeys.indexOf(recordName) else {
            return nil
        }
        return NSIndexPath(forRow: row, inSection: 0)
    }
    
    func fetchSalonFromCloud(recordName:String) {
        let containerID = Coredata.sharedInstance.iCloudContainerIdentifier
        let container = CKContainer(identifier: containerID)
        let recordID = CKRecordID(recordName: recordName)
        container.publicCloudDatabase.fetchRecordWithID(recordID) { record, error in
            guard let record = record else {
                if let userInfo = error?.userInfo {
                    if let retryAfter = userInfo["retryAfter"] as? Int64 {
                        let after = dispatch_time(DISPATCH_TIME_NOW, retryAfter)
                        dispatch_after(after, dispatch_get_main_queue()) {
                            self.fetchSalonFromCloud(recordName)
                        }
                    } else {
                        // Handle other errors by ignoring them
                    }
                }
                return
            }
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                let recordName = record.recordID.recordName
                if let indexPath = self.indexPathForRecordName(recordName) {
                    self.salonRecordsDictionary[recordName] = record
                    self.tableView.beginUpdates()
                    self.configureCellAtIndexPath(indexPath)
                    self.tableView.endUpdates()
                }
            }
        }
    }
    
}

