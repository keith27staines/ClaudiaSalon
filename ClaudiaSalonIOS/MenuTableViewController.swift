//
//  MenuTableViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 09/04/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit
import CloudKit

class MenuTableViewController: UITableViewController {

    @IBOutlet weak var salonName: UILabel!
    
    
    @IBOutlet weak var salonAddress: UILabel!
    
    
    @IBOutlet weak var appStartSwitch: UISwitch!
    @IBOutlet weak var importProcessingSwitch: UISwitch!
    @IBOutlet weak var exportProcessingSwitch: UISwitch!
    
    @IBOutlet weak var forgetButton: UIButton!
    
    @IBOutlet weak var refreshButton: UIButton!
    
    @IBOutlet weak var refreshLabel: UILabel!
    
    @IBOutlet weak var forgetLabel: UILabel!
    
    @IBAction func refreshTapped(sender: AnyObject) {
        self.performSegueWithIdentifier("GotoImporter", sender: self)
    }
    
    @IBAction func forgetTapped(sender: AnyObject) {
    }
    
    @IBAction func appStartSwitchChanged(sender: UISwitch) {
        AppDelegate.setAppStartsWithCloudUpdating(sender.on)
    }
    
    @IBAction func importProcessingSwitchChanged(sender: UISwitch) {
        AppDelegate.setProcessCloudNotifications(sender.on)
    
    }

    @IBAction func exportProcessingSwitchChanged(sender: UISwitch) {
        AppDelegate.setExportChangesToCloud(sender.on)
    }
    override func viewDidLoad() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(MenuTableViewController.done(_:)))
        self.appStartSwitch.on = AppDelegate.appStartsWithCloudUpdating()
        self.importProcessingSwitch.on = AppDelegate.processCloudNotifications()
        self.exportProcessingSwitch.on = AppDelegate.exportChangesToCloud()
    }
    
    func enableSalonSpecificControls(enable:Bool) {
        self.refreshLabel.enabled = enable
        self.refreshButton.enabled = enable
        self.forgetLabel.enabled = enable
        self.forgetButton.enabled = enable
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        guard let recordName = AppDelegate.defaultSalonKey() else {
            self.enableSalonSpecificControls(false)
            return
        }
        self.enableSalonSpecificControls(true)
        self.fetchSalonFromCloud(recordName)
    }
    
    func fetchSalonFromCloud(salonRecordName:String) {
        let containerID = AppDelegate.cloudContainerID
        let container = CKContainer(identifier: containerID)
        let recordID = CKRecordID(recordName: salonRecordName)
        container.publicCloudDatabase.fetchRecordWithID(recordID) { record, error in
            guard let record = record else {
                if let userInfo = error?.userInfo {
                    if let retryAfter = userInfo["retryAfter"] as? Int64 {
                        let after = dispatch_time(DISPATCH_TIME_NOW, retryAfter)
                        dispatch_after(after, dispatch_get_main_queue()) {
                            self.fetchSalonFromCloud(salonRecordName)
                        }
                    } else {
                        // Handle other errors by ignoring them
                    }
                }
                return
            }
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                self.salonName.text = record["name"] as? String
                let addressLine1 = record["addressLine1"] as? String
                let addressLine2 = record["addressLine2"] as? String
                let postcode = record["postcode"] as? String
                var address = addressLine1
                if address != nil && addressLine2 != nil {
                    address = address! + ", " + addressLine2!
                }
                if address != nil && postcode != nil {
                    address = address! + ", " + postcode!
                }
                self.salonAddress.text = address
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func done(sender:AnyObject?) {
        self.parentViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GotoImporter" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let importController = navigationController.topViewController as! ImportViewController
            importController.salonName = self.salonName.text!
            importController.bulkImportCompletionBlock = {
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    self.dismissViewControllerAnimated(true, completion: nil)
                    self.tableView.reloadData()
                }
            }
            return
        }
        if segue.identifier == "GotoSelectSalon" {
            return
        }
    }
}
