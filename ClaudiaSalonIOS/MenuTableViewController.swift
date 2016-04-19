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
    @IBOutlet weak var importProcessingSwitch: UISwitch!
    @IBOutlet weak var exportProcessingSwitch: UISwitch!
    @IBOutlet weak var forgetButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var refreshLabel: UILabel!
    @IBOutlet weak var forgetLabel: UILabel!

    @IBOutlet weak var allowExportLabel: UILabel!
    @IBOutlet weak var allowImportLabel: UILabel!
    @IBAction func refreshTapped(sender: AnyObject) {
        self.performSegueWithIdentifier("GotoImporter", sender: self)
    }
    
    @IBAction func forgetTapped(sender: AnyObject) {
    }
    
    @IBAction func importProcessingSwitchChanged(sender: UISwitch) {
        if sender.on {
            Coredata.sharedInstance.importController.resumeCloudNotificationProcessing()
        } else {
            Coredata.sharedInstance.importController.suspendCloudNotificationProcessing()
        }
    }

    @IBAction func exportProcessingSwitchChanged(sender: UISwitch) {
        if sender.on {
            Coredata.sharedInstance.exportController.resumeExportIterations()
        } else {
            Coredata.sharedInstance.exportController.suspendExportIterations()
        }
    }
    override func viewDidLoad() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(MenuTableViewController.done(_:)))
        if let coredata = Coredata.sharedInstance {
            self.importProcessingSwitch.on = !coredata.importController.isSuspended()
            self.exportProcessingSwitch.on = !coredata.exportController.isSuspended()
        } else {
            self.importProcessingSwitch.on = false
            self.exportProcessingSwitch.on = false
        }
    }
    
    func enableSalonSpecificControls(enable:Bool) {
        self.refreshLabel.enabled = enable
        self.refreshButton.enabled = enable
        self.forgetLabel.enabled = enable
        self.forgetButton.enabled = enable
        self.importProcessingSwitch.enabled = enable
        self.exportProcessingSwitch.enabled = enable
        self.allowExportLabel.enabled = enable
        self.allowImportLabel.enabled = enable
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.salonName.text = "Select a Salon"
        self.salonAddress.text = " "
        self.enableSalonSpecificControls(false)
        guard let recordName = AppDelegate.defaultSalonKey() else {
            return
        }
        
        guard let coredata = Coredata.sharedInstance else {
            self.salonAddress.text = "Data refresh is required"
            self.refreshLabel.enabled = true
            self.refreshButton.enabled = true
            self.forgetLabel.enabled = true
            self.forgetButton.enabled = true
            self.fetchSalonFromCloud(recordName)
            return
        }

        guard let salon = Salon.defaultSalon(coredata.managedObjectContext),
              let name = salon.salonName else {
                self.salonAddress.text = "Data refresh is required"
                self.refreshLabel.enabled = true
                self.refreshButton.enabled = true
                self.forgetLabel.enabled = true
                self.forgetButton.enabled = true
                self.fetchSalonFromCloud(recordName)
                return
        }
        self.salonName.text = name
        self.salonAddress.text = self.constructSingleLineAddress(salon.addressLine1, addressLine2: salon.addressLine2, postcode: salon.postcode)
        self.enableSalonSpecificControls(true)
    }
    
    func constructSingleLineAddress(addressLine1: String?, addressLine2: String?, postcode: String?) -> String {
        let addressLine1 = addressLine1
        let addressLine2 = addressLine2
        let postcode = postcode
        var address = addressLine1
        if address != nil && addressLine2 != nil {
            address = address! + ", " + addressLine2!
        }
        if address != nil && postcode != nil {
            address = address! + ", " + postcode!
        }
        return address ?? " "
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
