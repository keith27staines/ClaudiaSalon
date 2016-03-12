//
//  CloudImporter.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 12/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class BQCloudImporter {
    private lazy var synchQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    var downloads = [String:DownloadInfo]()
    var downloadWasUpdated: ((info:DownloadInfo) -> Void)?
    var downloadCompleted: ((info:DownloadInfo) -> Void)?
    var allDownloadsComplete: ((withErrors:[NSError]?)->Void)?

    private let publicDatabase = CKContainer(identifier: "iCloud.uk.co.ClaudiasSalon.ClaudiaSalon").publicCloudDatabase
    private let salonCloudRecordName = "44736040-37E7-46B0-AAAB-8EA90A6C99C4"
    private let cloudSalonReference : CKReference? = nil
    private var downloadedRecords = [CKRecord]()
    private var queryOperations = Set<CKQueryOperation>()
    private let moc = Coredata.sharedInstance.backgroundContext
    
    private var appointments = [Appointment]()
    private var customers = [Customer]()
    private var employees = [Employee]()
    private var sales = [Sale]()
    private var saleItems = [SaleItem]()
    private var salons = [Salon]()
    private var services = [Service]()
    private var serviceCategories = [ServiceCategory]()
    
    private (set) var cancelled = false
    
    init() {
        self.reinitialiseDatastructures()
    }
    
    private func reinitialiseDatastructures() {
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
    func cancelImport() {
        self.synchQueue.addOperationWithBlock() {
            for operation in self.queryOperations {
                operation.cancel()
            }
            self.cancelled = true
        }
    }

    private func addQueryOperationToQueueForType(type:CloudRecordType) {
        let downloadInfoForType = DownloadInfo(recordType: type)
        downloads[type.rawValue] = downloadInfoForType
        let queryOperation = self.fetchRecordsFromCloudOperation(type.rawValue)
        self.ThreadSafeAddQueryOperationToQueue(queryOperation)
    }
    
    
    private func handleDownloadedRecord(operation:CKQueryOperation,record:CKRecord) {
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
    
    private func handleQueryCompletion(operation:CKQueryOperation,cursor:CKQueryCursor?,error:NSError?) {
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
                self.createShallowCoredataObjectsFromCloudRecords(self.downloadedRecords)
            }
        }
        
    }
    
    private func createShallowCoredataObjectsFromCloudRecords(records:[CKRecord]) {
        for record in records {
            let type = record.recordType
            let cType = CloudRecordType.typeFromCloudRecordName(type)
            moc.performBlock() {
                switch cType {
                case .CRAppointment:
                    self.appointments.append(Appointment.newObjectWithMoc(self.moc))
                case .CRCustomer:
                    self.customers.append(Customer.newObjectWithMoc(self.moc))
                case .CREmployee:
                    self.employees.append(Employee.newObjectWithMoc(self.moc))
                case .CRSale:
                    self.sales.append(Sale.newObjectWithMoc(self.moc))
                case .CRSaleItem:
                    self.saleItems.append(SaleItem.newObjectWithMoc(self.moc))
                case .CRSalon:
                    self.salons.append(Salon(moc: self.moc))
                case .CRService:
                    self.services.append(Service.newObjectWithMoc(self.moc))
                case .CRServiceCategory:
                    self.serviceCategories.append(ServiceCategory.newObjectWithMoc(self.moc))
                }
            }
        }
    }
    private func fetchCoredataObjectForCloudRecord(record:CKRecord)->NSManagedObject? {
        let moc = Coredata.sharedInstance.backgroundContext
        let type = record.recordType
        let cType = CloudRecordType.typeFromString(type)!
        let cloudID = record.recordID.recordName
        let entityName = cType.coredataEntityName()
        let predicate:NSPredicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        let request = NSFetchRequest(entityName: entityName)
        request.predicate = predicate
        let fetches = try! moc.executeFetchRequest(request)
        assert(fetches.count < 2, "More than one managed object of type \(entityName) for cloud id = \(cloudID)")
        if fetches.count == 0 { return nil }
        guard let managedObject = fetches[0] as? NSManagedObject else {
            fatalError("Managed Object Context returned an unexpected type")
        }
        return managedObject
    }
    private func downloadsDidCompleteSuccessfully() -> Bool {
        if self.queryOperations.count > 0 { return false } // Some queries still running
        for (_,info) in self.downloads {
            if let _ = info.error { return false } // Finished but with an error
            if !info.finished { return false }  // Still running or waiting to run
        }
        // Everything finished without error
        return true
    }
    
    private func ThreadSafeAddQueryOperationToQueue(operation:CKQueryOperation) {
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
