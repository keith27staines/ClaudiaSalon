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
    
    @IBOutlet weak var salonCell: UITableViewCell!
    
    @IBOutlet weak var customersCell: UITableViewCell!
    
    @IBOutlet weak var staffCell: UITableViewCell!
    
    @IBOutlet weak var servicesCell: UITableViewCell!
    
    @IBOutlet weak var serviceCategoriesCell: UITableViewCell!
    
    @IBOutlet weak var salonActivitySpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var customersActivitySpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var staffActivitySpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var servicesActivitySpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var serviceCategoriesActivitySpinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        self.salonActivitySpinner.hidden = true
        self.customersActivitySpinner.hidden = true
        self.staffActivitySpinner.hidden = true
        self.servicesActivitySpinner.hidden = true
        self.serviceCategoriesActivitySpinner.hidden = true
        self.salonActivitySpinner.stopAnimating()
        self.customersActivitySpinner.stopAnimating()
        self.staffActivitySpinner.stopAnimating()
        self.servicesActivitySpinner.stopAnimating()
        self.serviceCategoriesActivitySpinner.stopAnimating()
    }
}

enum CloudRecordType: String {
    
    case CRSalon = "iCloudSalon"
    case CRCustomer = "iCloudCustomer"
    case CREmployee = "iCloudEmployee"
    case CRService = "icloudService"
    case CRServiceCategory = "iCloudServiceCategory"
    case CRAppointment = "iCloudAppointment"
    case CRSale = "iCloudSale"
    case CRSaleItem = "iCloudSaleItem"
    
    static func typesAsArray() -> [CloudRecordType] {
        let array = [CRSalon,CRCustomer,CREmployee,CRService,CRServiceCategory,CRAppointment,CRSale,CRSaleItem]
        return array
    }
    static func typesAsDictionary() -> [String:CloudRecordType] {
        return [
            CRSalon.rawValue: CRSalon,
            CRCustomer.rawValue: CRCustomer,
            CREmployee.rawValue: CREmployee,
            CRService.rawValue: CRService,
            CRServiceCategory.rawValue: CRServiceCategory,
            CRAppointment.rawValue: CRAppointment,
            CRSale.rawValue: CRSale,
            CRSaleItem.rawValue: CRSaleItem
        ];
    }
    static func typeFromString(string:String) -> CloudRecordType? {
        let d = self.typesAsDictionary()
        return d[string]
    }
}

class BQCloudImporter {
    let publicDatabase = CKContainer(identifier: "iCloud.uk.co.ClaudiasSalon.ClaudiaSalon").publicCloudDatabase
    let salonCloudRecordName = "44736040-37E7-46B0-AAAB-8EA90A6C99C4"
    let cloudSalonReference : CKReference? = nil
    var downloadedRecords: [CKRecord]
    var downloads: [String:DownloadInfo]
    var queryOperations: [CKQueryOperation]
    private (set) var cancelled = false
    
    
    init() {
        downloadedRecords = [CKRecord]()
        downloads = [String:DownloadInfo]()
        queryOperations = [CKQueryOperation]()
    }
    
    func reinitialiseDatastructures() {
        downloadedRecords.removeAll(keepCapacity: true)
        downloads.removeAll(keepCapacity: true)
        queryOperations.removeAll(keepCapacity: true)
    }
    struct DownloadInfo {
        var recordType: CloudRecordType
        var activeOperations = 0
        var recordsDownloaded = 0
        var error:NSError?
        var downloadStatus: String = ""
    }
    
    func startImport() {
        // Start from clean slate
        self.deleteAllCoredataObjects()
        
        for recordType in CloudRecordType.typesAsArray() {
            let downloadInfoForType = DownloadInfo(recordType: recordType, activeOperations: 0, recordsDownloaded: 0, error: nil, downloadStatus: "waiting...")
            downloads[recordType.rawValue] = downloadInfoForType
            let queryOperation = self.fetchRecordsFromCloudOperation(recordType.rawValue)
            self.addQueryOperationToQueue(queryOperation)
        }
    }
    
    func cancelImport() {
        for operation in self.queryOperations {
            operation.cancel()
        }
        self.cancelled = true
    }
    
    func handleDownloadedRecord(operation:CKQueryOperation,record:CKRecord) {
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            self.downloadedRecords.append(record)
            guard let name = operation.name else {
                fatalError("Operation lacks a name and so cannot be processed")
            }
            guard var info = self.downloads[name] else {
                fatalError("The operation isn't recognised")
            }
            info.recordsDownloaded++
            info.downloadStatus = "downloading..."
            self.downloads[name] = info
        }
    }
    func handleQueryCompletion(operation:CKQueryOperation,error:NSError?) {
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            guard let name = operation.name else {
                fatalError("Operation lacks a name and so cannot be processed")
            }
            guard var info = self.downloads[name] else {
                fatalError("The operation isn't recognised")
            }
            info.activeOperations--
            if info.activeOperations == 0 {
                if error == nil {
                    info.downloadStatus = "Finished"
                } else {
                    info.downloadStatus = "Finished with error \(error?.localizedDescription)"
                }
            }
            info.error = error
            self.downloads[name] = info
            let index = self.queryOperations.indexOf(operation)
            self.queryOperations.removeAtIndex(index!)
            if self.cancelled {
                self.deleteAllCoredataObjects()
                self.reinitialiseDatastructures()
            }
        }
        
    }
    
    func addQueryOperationToQueue(operation:CKQueryOperation) {
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            self.queryOperations.append(operation)
            self.publicDatabase.addOperation(operation)
        }
    }
}

extension BQCloudImporter {
    func fetchRecordsFromCloudOperation(recordType:String) -> CKQueryOperation {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.name = recordType
        queryOperation.queryCompletionBlock = { cursor, error in
            if let cursor = cursor {
                let nextQueryOperation = CKQueryOperation(cursor: cursor)
                nextQueryOperation.name = queryOperation.name
                nextQueryOperation.queryCompletionBlock = queryOperation.queryCompletionBlock
                nextQueryOperation.recordFetchedBlock = queryOperation.recordFetchedBlock
                self.addQueryOperationToQueue(nextQueryOperation)
            }
            self.handleQueryCompletion(queryOperation,error:error)
        }
        queryOperation.recordFetchedBlock = { record in
            self.handleDownloadedRecord(queryOperation, record: record)
        }
        return queryOperation
    }

}

extension BQCloudImporter {
    func performInitialImport() {
        let salonRecordID = CKRecordID(recordName: self.salonCloudRecordName)
        self.publicDatabase.fetchRecordWithID(salonRecordID) { (record, error) -> Void in
            guard error == nil else {
                return
            }
            guard let record = record else {
                return
            }
            let moc = Coredata.sharedInstance.backgroundContext
            let salon = Salon.makeFromCloudRecord(record, moc: moc)
            if let anonCustomerRef = record["anonymousCustomerReference"] as? CKReference {
                let customerID = anonCustomerRef.recordID
                self.publicDatabase.fetchRecordWithID(customerID, completionHandler: { (customerRecord, error) -> Void in
                    if error != nil {
                        fatalError("Failed to download the Anonymous Customer from cloud")
                    } else {
                        if let anon = Customer.fetchForCloudID(customerID.recordName, moc: moc) {
                            anon.updateFromCloudRecordIfNeeded(customerRecord!)
                            salon.anonymousCustomer = anon
                        } else {
                            let anon = Customer.makeFromCloudRecord(customerRecord!, moc: moc)
                            salon.anonymousCustomer = anon
                        }
                    }
                    moc.performBlock() {
                        Coredata.sharedInstance.saveContext()
                    }
                })
            }
            
        }
        
    }
    func deleteAllCoredataObjects() {
        let entities = ["Salon", "Customer", "Employee", "Service", "ServiceCategory", "Appointment", "Sale", "SaleItem"]
        for entity in entities {
            self.deleteEntity(entity)
        }
        Coredata.sharedInstance.saveContext()
    }
    func deleteEntity(name:String) {
        let fetchRequest = NSFetchRequest(entityName: name)
        let yesPredicate = NSPredicate(value: true)
        fetchRequest.predicate = yesPredicate
        let moc = Coredata.sharedInstance.backgroundContext
        moc.performBlockAndWait() {
            let fetchedObjects = try! moc.executeFetchRequest(fetchRequest)
            for modelObject in fetchedObjects {
                moc.deleteObject(modelObject as! NSManagedObject)
            }
        }
    }
}
