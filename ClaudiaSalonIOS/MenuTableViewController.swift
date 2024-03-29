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
        guard let _ = Coredata.sharedInstance else {
            let alert = UIAlertController(title: "Can't refresh data", message: "You must select a salon first", preferredStyle: .Alert)
            let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(alertAction)
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        let alert = UIAlertController(title: "Refresh data?", message: "Are you sure you want to refresh data now? Any changes you have made that have not been exported from this device (orange cloud) may be lost", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let refreshAction = UIAlertAction(title: "Refresh", style: .Destructive) { _ in
            self.performSegueWithIdentifier("GotoImporter", sender: self)
        }
        alert.addAction(cancelAction)
        alert.addAction(refreshAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func resetBadgeCount(sender: AnyObject) {
        let app = UIApplication.sharedApplication()
        if let appDelegate = app.delegate as? AppDelegate {
            appDelegate.setBadgeCount(0)
        }
    }
    
    @IBAction func forgetCloudNotificationSubscriptions() {
        let container = CKContainer(identifier: AppDelegate.cloudContainerID)
        let database = container.publicCloudDatabase
        CloudNotificationSubscriber.deleteAllCloudNotificationSubscriptions(database) { result in
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                switch result {
                case .success:
                    let alert = UIAlertController(title: "Cloud Notifications Updated", message: "This app has successfully unsubscribed from cloud notifications", preferredStyle: .Alert)
                    let action = UIAlertAction(title: "Done", style: .Default, handler: nil)
                    alert.addAction(action)
                    self.presentViewController(alert, animated: false, completion: nil)
                case .failure(let error):
                    print("Failed to unsubscribe cloud notifications with error \(error)")
                    let alert = UIAlertController(title: "Update failed", message: "Failed to unsubscribe from cloud notifications.", preferredStyle: .Alert)
                    let action = UIAlertAction(title: "Done", style: .Default, handler: nil)
                    alert.addAction(action)
                    self.presentViewController(alert, animated: false, completion: nil)
                }
            }
            
        }
    }
    
    @IBAction func forgetTapped(sender: AnyObject) {
        guard let recordName = AppDelegate.defaultSalonKey() else {
            let alert = UIAlertController(title: "Can't forget Salon", message: "You must select a salon to forget", preferredStyle: .Alert)
            let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(alertAction)
            self.presentViewController(alert, animated: true, completion: nil)
            return
        }
        
        let alert = UIAlertController(title: "Forget Salon?", message: "Are you sure you want to remove all data for this salon from this device?", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        let forgetAction = UIAlertAction(title: "Remove", style: .Destructive) { _ in
            Coredata.forgetSalon(recordName) { success in
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    var alert:UIAlertController
                    if success {
                        AppDelegate.forgetSalon(recordName)
                        alert = UIAlertController(title: "Salon forgotten", message: "All data related to this salon has been removed from this device", preferredStyle: .Alert)
                        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
                        alert.addAction(action)
                    } else {
                        alert = UIAlertController(title: "Error Forgetting Salon", message: "Not all data related to this salon has been removed from this device due to a network problem. Please try again later.", preferredStyle: .Alert)
                        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
                        alert.addAction(action)
                    }
                    self.presentViewController(alert, animated: true, completion: nil)
                    self.salonDidChange()
                }
            }
        }
        alert.addAction(cancelAction)
        alert.addAction(forgetAction)
        self.presentViewController(alert, animated: true, completion: nil)
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
    
    func salonDidChange() {
        self.salonName.text = "Select or Add a Salon"
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.salonDidChange()
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
