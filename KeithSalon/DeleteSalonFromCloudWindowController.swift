//
//  DeleteSalonFromCloudWindowController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 30/04/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Cocoa
import CloudKit

class DeleteSalonFromCloudWindowController: NSWindowController {

    @IBOutlet weak var tableView:NSTableView!
    @IBOutlet weak var recordNameField:NSTextField!
    
    override var windowNibName: String? { return "DeleteSalonFromCloudWindowController" }
    private var fetchOperation: FetchFromCloudOperation?
    private var deleteOperation: DeleteFromCloudOperation?
    private var tableInformation = DeletionInfo()
    
    lazy var deleteWorkerQueue:NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "Delete queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    override func windowDidLoad() {
        super.windowDidLoad()

        if let salon = NSDocumentController.sharedDocumentController().currentDocument as? AMCSalonDocument {
            self.recordNameField.stringValue = salon.salon.bqCloudID ?? ""
        }
    }
    
    @IBAction func unsubscribeFromCloudNotifications(sender: AnyObject) {
        let container = CKContainer.defaultContainer()
        let database = container.publicCloudDatabase
        CloudNotificationSubscriber.deleteAllCloudNotificationSubscriptions(database) { result in
            let alert = NSAlert()
            switch result {
            case .success:
                alert.alertStyle = .InformationalAlertStyle
                alert.messageText = "All notifications were unsubscribed"
                alert.informativeText = "Notifications will no longer be received by this app"
                alert.addButtonWithTitle("Close")
            case .failure(let error):
                alert.alertStyle = .WarningAlertStyle
                alert.messageText = "Failed to delete notification subscriptions"
                alert.informativeText = "Notifications might continue to be received. \nError was:\(error)"
                alert.addButtonWithTitle("Close")
                alert.beginSheetModalForWindow(self.window!, completionHandler: nil)
            }
            NSOperationQueue.mainQueue().addOperationWithBlock {
                alert.beginSheetModalForWindow(self.window!, completionHandler: nil)
            }
        }
    }
    
    @IBAction func startDelete(sender: AnyObject) {
        let recordName = self.recordNameField.stringValue
        guard recordName.characters.count >= 16 else {
            return
        }
        self.fetchOperation = nil
        self.tableView.reloadData()
        let containerID = CKContainer.defaultContainer().containerIdentifier!
        self.fetchOperation = FetchFromCloudOperation(containerID: containerID, salonRecordName: recordName, completionResult: { tableInformation in
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                self.tableInformation = tableInformation
                self.tableView.reloadData()
                if tableInformation.state == DeleteOperationStates.FetchFinished {
                    self.deleteOperation = DeleteFromCloudOperation(containerID: containerID, salonRecordName: recordName, deletionInfo: self.tableInformation, completionResult: { (tableInformation) in
                        self.tableInformation = tableInformation
                        self.tableView.reloadData()
                    })
                    self.deleteWorkerQueue.addOperation(self.deleteOperation!)                    
                }
            }
        })
        
        self.deleteWorkerQueue.addOperation(self.fetchOperation!)
    }
}


extension DeleteSalonFromCloudWindowController : NSTableViewDataSource {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.tableInformation.recordTypeInformation.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let recordType = self.recordTypeForRow(row)
        guard let recordInfo = self.tableInformation.recordTypeInformation[recordType] else {
            return ""
        }
        guard let columnIdentifier = tableColumn?.identifier else {
            return ""
        }
        switch columnIdentifier {
        case "recordType":
            return recordInfo.recordType.rawValue
        case "recordCount":
            return String(recordInfo.records.count)
        case "downloadStatus":
            return recordInfo.status.rawValue
        case "error":
            return recordInfo.error?.localizedDescription
        default:
            return "XXXX"
        }
    }

    func recordTypeForRow(row:Int) -> ICloudRecordType {
        switch row {
        case 0:
            return ICloudRecordType.Salon
        case 1:
            return ICloudRecordType.Employee
        case 2:
            return ICloudRecordType.Customer
        case 3:
            return ICloudRecordType.Appointment
        case 4:
            return ICloudRecordType.Sale
        case 5:
            return ICloudRecordType.SaleItem
        case 6:
            return ICloudRecordType.ServiceCategory
        case 7:
            return ICloudRecordType.Service
        default:
            fatalError("Row \(row) doesn't correspond to a recordType")
        }
    }
}