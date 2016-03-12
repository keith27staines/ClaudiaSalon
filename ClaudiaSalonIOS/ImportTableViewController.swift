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
        let array = [CRSalon,CRCustomer,CREmployee,CRServiceCategory,CRService,CRAppointment,CRSale,CRSaleItem]
        return array
    }
    func coredataEntityName() -> String{
        return CloudRecordType.coredataEntityNameForType(self)
    }
    static func coredataEntityNameForType(type:CloudRecordType) -> String {
        switch type {
        case .CRSalon: return "Salon"
        case .CRCustomer: return "Customer"
        case .CREmployee: return "Employee"
        case .CRServiceCategory: return "Service Category"
        case .CRService: return "Service"
        case .CRAppointment: return "Appointment"
        case .CRSale: return "Sale"
        case .CRSaleItem: return "SaleItem"
        }
    }
    func index() -> Int {
        return CloudRecordType.indexForType(self)
    }
    static func indexForType(type:CloudRecordType) -> Int {
        switch type {
        case .CRSalon: return 0
        case .CRCustomer: return 1
        case .CREmployee: return 2
        case .CRServiceCategory: return 3
        case .CRService: return 4
        case .CRAppointment: return 5
        case .CRSale: return 6
        case .CRSaleItem: return 7
        }
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

struct DownloadInfo {
    var recordType: CloudRecordType
    var activeOperations = 0
    var recordsDownloaded = 0
    var error:NSError?
    var downloadStatus: String {
        if self.waiting {
            if activeOperations == 0 {
                return ""
            } else {
                return "Waiting for server"
            }
        }
        if self.executing { return "\(recordsDownloaded) downloaded" }
        if self.finished {
            if error != nil {
                return "Encountered error after \(recordsDownloaded) records"
            } else {
                return "Finished downloading \(recordsDownloaded) record(s)"
            }
        }
        assertionFailure("Invalid state")
        return "Invalid state"
    }
    var executing = false
    var finished = false
    var waiting = true
    init(recordType:CloudRecordType) {
        self.recordType = recordType
    }
}

class BQCloudImporter {
    lazy var synchQueue: NSOperationQueue = {
       let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    let publicDatabase = CKContainer(identifier: "iCloud.uk.co.ClaudiasSalon.ClaudiaSalon").publicCloudDatabase
    let salonCloudRecordName = "44736040-37E7-46B0-AAAB-8EA90A6C99C4"
    let cloudSalonReference : CKReference? = nil
    var downloadedRecords = [CKRecord]()
    var downloads = [String:DownloadInfo]()
    var queryOperations = Set<CKQueryOperation>()
    private (set) var cancelled = false
    private var downloadWasUpdated: ((info:DownloadInfo) -> Void)?
    private var downloadCompleted: ((info:DownloadInfo) -> Void)?
    private var allDownloadsComplete: ((withErrors:[NSError]?)->Void)?
    
    init() {
        self.reinitialiseDatastructures()
    }
    
    func reinitialiseDatastructures() {
        self.synchQueue.addOperationWithBlock() {
            self.downloadedRecords.removeAll(keepCapacity: true)
            self.downloads.removeAll()
            for recordType in CloudRecordType.typesAsArray() {
                let info = DownloadInfo(recordType: recordType)
                self.downloads[recordType.rawValue] = info
            }
            self.queryOperations.removeAll()
        }
    }
    
    func startImport() {
        self.synchQueue.addOperationWithBlock() {
            self.deleteAllCoredataObjects()
            for recordType in CloudRecordType.typesAsArray() {
                self.addQueryOperationToQueueForType(recordType)
            }
        }
    }
    func addQueryOperationToQueueForType(type:CloudRecordType) {
        let downloadInfoForType = DownloadInfo(recordType: type)
        downloads[type.rawValue] = downloadInfoForType
        let queryOperation = self.fetchRecordsFromCloudOperation(type.rawValue)
        self.ThreadSafeAddQueryOperationToQueue(queryOperation)
    }
    
    func cancelImport() {
        self.synchQueue.addOperationWithBlock() {
            for operation in self.queryOperations {
                operation.cancel()
            }
            self.cancelled = true
        }
    }
    
    func handleDownloadedRecord(operation:CKQueryOperation,record:CKRecord) {
        self.synchQueue.addOperationWithBlock() {
            self.downloadedRecords.append(record)
            guard let name = operation.name else {
                fatalError("Operation lacks a name and so cannot be processed")
            }
            guard var info = self.downloads[name] else {
                fatalError("The operation isn't recognised")
            }
            info.waiting = false
            info.executing = true
            info.recordsDownloaded++
            self.downloads[name] = info
            if let callback = self.downloadWasUpdated {
                callback(info: info)
            }
        }
    }
    
    func handleQueryCompletion(operation:CKQueryOperation,cursor:CKQueryCursor?,error:NSError?) {
        self.synchQueue.addOperationWithBlock() {
            guard let name = operation.name else {
                fatalError("Operation lacks a name and so cannot be processed")
            }
            guard var info = self.downloads[name] else {
                fatalError("The operation isn't recognised")
            }
            info.activeOperations--
            if info.activeOperations == 0 {
                info.waiting = false
                info.executing = false
                info.finished = true
            }
            info.error = error
            self.downloads[name] = info
            
            if let cursor = cursor  {
                if !self.cancelled {
                    let nextQueryOperation = CKQueryOperation(cursor: cursor)
                    nextQueryOperation.name = operation.name
                    nextQueryOperation.queryCompletionBlock = { cursor, error in
                        self.handleQueryCompletion(nextQueryOperation,cursor:cursor,error:error)
                    }
                    nextQueryOperation.recordFetchedBlock = { record in
                        self.handleDownloadedRecord(nextQueryOperation, record: record)
                    }
                    self.unsafeAddQueryOperationToQueue(nextQueryOperation)
                }
            }
            
            if self.downloads[name]!.activeOperations == 0 {
                if let callback = self.downloadCompleted {
                    callback(info: info)
                }
            }
            self.queryOperations.remove(operation)
            if self.cancelled {
                self.deleteAllCoredataObjects()
                self.reinitialiseDatastructures()
            }
            
            if self.downloadsDidCompleteSuccessfully() {
                print("Ready to process \(self.downloadedRecords.count) downloaded records")
            }
        }
        
    }
    func downloadsDidCompleteSuccessfully() -> Bool {
        if self.queryOperations.count > 0 { return false } // Some queries still running
        for (_,info) in self.downloads {
            if let _ = info.error { return false } // Finished but with an error
            if !info.finished { return false }  // Still running or waiting to run
            
        }
        // Everything finished without error
        return true
    }

    func ThreadSafeAddQueryOperationToQueue(operation:CKQueryOperation) {
        self.synchQueue.addOperationWithBlock() {
            self.unsafeAddQueryOperationToQueue(operation)
        }
    }
    private func unsafeAddQueryOperationToQueue(operation:CKQueryOperation) {
        let recordType = operation.name!
        var info = self.downloads[recordType]!
        info.activeOperations++
        self.downloads[recordType] = info
        self.queryOperations.insert(operation)
        self.publicDatabase.addOperation(operation)
    }
}

extension BQCloudImporter {
    func fetchRecordsFromCloudOperation(recordType:String) -> CKQueryOperation {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.name = recordType
        queryOperation.queryCompletionBlock = { cursor, error in
            self.handleQueryCompletion(queryOperation,cursor:cursor,error:error)
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
