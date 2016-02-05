
//
//  BQCoredataExportController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class BQCoredataExportController {
    let namePrefix = "BQCoredataExporter"
    let exportOperation:BQExportModifiedCoredataOperation
    let exportQueue:NSOperationQueue
    let managedObjectContext:NSManagedObjectContext!
    let salon:Salon!
    let deletionRequestList:BQDeletionRequestList
    var cancelled = true
    var nextRunTime = dispatch_time(DISPATCH_TIME_NOW, Int64(30 * NSEC_PER_SEC))
    
    init(managedObjectContext:NSManagedObjectContext, salon:Salon, startImmediately:Bool) {
        self.salon = salon
        self.managedObjectContext = managedObjectContext
        exportQueue = NSOperationQueue()
        exportQueue.name = namePrefix + "Queue"
        deletionRequestList = BQDeletionRequestList(managedObjectContext: self.managedObjectContext)
        exportOperation = BQExportModifiedCoredataOperation(managedObjectContext: self.managedObjectContext, salon: self.salon, deletionRequestList: deletionRequestList)
        exportOperation.name = namePrefix + "BQExportOperation"

        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: nil, queue: exportQueue) { notification in
            // Managed objects just-deleted from the managed object context must be added to a deletion list for later removal from icloud
            if let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] {
                let deletedManagedObjects = deletedObjects as! Set<NSManagedObject>
                self.deletionRequestList.addCloudDeletionRequestsForLocallyDeletedObjects(deletedManagedObjects)
            }
        }
        
        if startImmediately {
            self.startExportIterations()
        }
    }
    /** Start iterating new export operations. Safe to call this twice because subsequent calls have no effect unless cancelled has been set after first call */
    func startExportIterations() {
        if !self.cancelled {
            // already running
            return
        }
        self.cancelled = false
        self.runExportIteration()
    }

    /** adds the export operation to the export queue and then calls itself until either the cancelled property becomes true or self is nil */
    private func runExportIteration() {
        weak var weakSelf = self
        if self.cancelled { return }
        let nextRunTime = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * NSEC_PER_SEC))
        dispatch_after(nextRunTime, dispatch_get_main_queue()) { () -> Void in
            if let strongSelf = weakSelf {
                if !(strongSelf.exportOperation.executing) {
                    print("Enquing operation")
                    strongSelf.exportQueue.addOperation(strongSelf.exportOperation)
                }
                print("Scheduling next iteration")
                strongSelf.runExportIteration()
            }
        }
    }
}

class BQExportModifiedCoredataOperation : NSOperation {
    let managedObjectContext:NSManagedObjectContext
    let modifedCoredata = Set<NSManagedObject>()
    let salon:Salon
    let deletionRequestList:BQDeletionRequestList
    var publicDatabase:CKDatabase!
    
    init(managedObjectContext:NSManagedObjectContext, salon:Salon, deletionRequestList:BQDeletionRequestList) {
        self.managedObjectContext = managedObjectContext
        self.deletionRequestList = deletionRequestList
        self.salon = salon
        super.init()
        self.name = "BQExportModifiedCoredataOperation"
        self.qualityOfService = .Background
    }
    
    // MARK:- Main function for this operation
    override func main() {
        if self.cancelled { return }
        publicDatabase = CKContainer.defaultContainer().publicCloudDatabase

        var recordIDsToDelete = [CKRecordID]()
        var recordsToSave = [CKRecord]()
        
        // Gather all modifed customers
        if self.cancelled { return }
        let modifiedCustomers = Customer.customersMarkedForExport(self.managedObjectContext) as Set<Customer>
        for modifiedObject in modifiedCustomers {
            let icloudObject = ICloudCustomer(coredataCustomer: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeFirstCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }

        // Gather all modifed Service categories
        if self.cancelled { return }
        let modifiedServiceCategories = ServiceCategory.serviceCategoriesMarkedForExport(self.managedObjectContext) as Set<ServiceCategory>
        for modifiedObject in modifiedServiceCategories {
            let icloudObject = ICloudServiceCategory(coredataServiceCategory: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeFirstCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Gather all modified Services
        if self.cancelled { return }
        let modifiedServices = Service.servicesMarkedForExport(self.managedObjectContext) as Set<Service>
        for modifiedObject in modifiedServices {
            let icloudObject = ICloudService(coredataService: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeFirstCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Gather all modified Employees
        if self.cancelled { return }
        let modifiedEmployees = Employee.employeesMarkedForExport(self.managedObjectContext) as Set<Employee>
        for modifiedObject in modifiedEmployees {
            let icloudObject = ICloudEmployee(coredataEmployee: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeFirstCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Gather all modified SaleItems
        if self.cancelled { return }
        let modifiedSaleItems = SaleItem.saleItemsMarkedForExport(self.managedObjectContext) as Set<SaleItem>
        for modifiedObject in modifiedSaleItems {
            guard modifiedObject.sale?.fromAppointment != nil else {
                continue
            }
            let icloudObject = ICloudSaleItem(coredataSaleItem: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeFirstCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Gather all modified Sales
        if self.cancelled { return }
        let modifiedSales = Sale.salesMarkedForExport(self.managedObjectContext) as Set<Sale>
        for modifiedObject in modifiedSales {
            guard modifiedObject.fromAppointment != nil else {
                continue
            }
            let icloudObject = ICloudSale(coredataSale: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeFirstCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Gather all modified Appointments
        if self.cancelled { return }
        let modifiedAppointments = Appointment.appointmentsMarkedForExport(self.managedObjectContext) as Set<Appointment>
        for modifiedObject in modifiedAppointments {
            let icloudObject = ICloudAppointment(coredataAppointment: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeFirstCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Now save the modified records
        self.saveModifiedRecordsToCloud(recordsToSave)
        
        // Gather records that must be deleted in icloud because their corresponding coredata objects have already been deleted
        let recordDeletionRequests = deletionRequestList.fetchAllPendingRequests()
        for deletionRequest in recordDeletionRequests {
            let recordID = deletionRequest.cloudkitRecordFromEmbeddedMetadata()!.recordID
            recordIDsToDelete.append(recordID)
        }
        self.deleteRecordIDsFromCloud(recordIDsToDelete)
    }
    
    // MARK:- Save records to cloud
    private func saveModifiedRecordsToCloud(saveRecords:[CKRecord]?) {
        guard let saveRecords = saveRecords where saveRecords.count > 0 else {
            return
        }
        let saveRecordsOperation = CKModifyRecordsOperation(recordsToSave: saveRecords, recordIDsToDelete: nil)
        saveRecordsOperation.savePolicy = .ChangedKeys
        
        // set the per-record block
        saveRecordsOperation.perRecordCompletionBlock = {(record,error)-> Void in
            guard let record = record else {
                return
            }
            guard let coredataID = record["coredataID"] else {
                assertionFailure("This record was expected to have a coredata id but none found")
                return
            }
            if let error = error {
                switch error {
                default:
                    // Operation failed unrecoverably so nothing we can do except maybe figure out why
                    print("Operation failed unrecoverably so nothing we can do except maybe figure out why")
                }
                return
            }
            let managedObject = self.managedObjectContext.objectForIDString(coredataID as! String)
            managedObject.markAsExported()
        }
        
        // Set the completion block
        saveRecordsOperation.modifyRecordsCompletionBlock = {(saveRecords, deleteRecords, error)-> Void in
            if let error = error {
                switch error {
                case CKErrorCode.LimitExceeded.rawValue:
                    // Need to recurse down to smaller operation
                    assertionFailure("Need to recurse down to smaller operation")
                    break
                case error.code == CKErrorCode.PartialFailure.rawValue:
                    print(error)
                case error.userInfo["CKErrorRetryAfterKey"] != nil:
                    // Transient failure - can retry this operation after a suitable delay
                    let retryAfter = error.userInfo["CKErrorRetryAfterKey"]!.doubleValue
                    self.retryOperation(saveRecordsOperation, waitInterval: retryAfter)
                default:
                    // Operation failed unrecoverably so nothing we can do except maybe figure out why
                    assertionFailure("Operation failed unrecoverably so nothing we can do except maybe figure out why")
                    return
                }
            }
        }
    
        // Actually submit the operation
        self.publicDatabase.addOperation(saveRecordsOperation)
    }
    
    // MARK:- Delete recordIDs from cloud
    func deleteRecordIDsFromCloud(recordIDsForDeletion:[CKRecordID]) {
        let deleteRecordsFromCloudOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsForDeletion)
        deleteRecordsFromCloudOperation.modifyRecordsCompletionBlock = { (_,recordIDsToDelete,error)->Void in
            guard let recordIDsToDelete = recordIDsToDelete else {
                return
            }
            let attemptedDeletions = Set(recordIDsToDelete)
            var failedDeletions = Set<CKRecordID>()
            var failedDeletionsDictionary: [CKRecordID:NSError]?
            if let error = error {
                switch error {
                case CKErrorCode.LimitExceeded.rawValue:
                    // Need to recurse down to smaller operation
                    assertionFailure("Need to recurse down to smaller operation")
                    break
                case error.code == CKErrorCode.PartialFailure.rawValue:
                    failedDeletionsDictionary = error.userInfo[CKPartialErrorsByItemIDKey] as! [CKRecordID:NSError]?
                    failedDeletions = Set(failedDeletionsDictionary!.keys)
                case error.userInfo["CKErrorRetryAfterKey"] != nil:
                    // Transient failure - can retry this operation after a suitable delay
                    let retryAfter = error.userInfo["CKErrorRetryAfterKey"]!.doubleValue
                    self.retryOperation(deleteRecordsFromCloudOperation, waitInterval: retryAfter)
                default:
                    // Operation failed unrecoverably so nothing we can do except maybe figure out why
                    assertionFailure("Operation failed unrecoverably so nothing we can do except maybe figure out why")
                    return
                }
            }
            // get the successes (successes = attempts - failures) and inform the deletion request list about the successes
            let successfullyDeleted = attemptedDeletions.subtract(failedDeletions)
            self.deletionRequestList.requestsSucceeded(successfullyDeleted)
            
            // Inform the deletion request list about any failures
            if let failedDeletionsDictionary = failedDeletionsDictionary {
                self.deletionRequestList.requestsFailed(failedDeletionsDictionary)
            }
        }
        self.publicDatabase.addOperation(deleteRecordsFromCloudOperation)
    }
    
    // MARK:- Retry operation
    func retryOperation(operation:CKModifyRecordsOperation, waitInterval:Double) {
        let waitIntervalNanoseconds = Int64(waitInterval * 1000_000_000.0)
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, waitIntervalNanoseconds)
        dispatch_after(dispatchTime, dispatch_get_main_queue()) { () -> Void in
            self.publicDatabase.addOperation(operation)
        }
    }
}