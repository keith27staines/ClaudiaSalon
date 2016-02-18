
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

// MARK:- Class BQCoredataExportController
class BQCoredataExportController {
    private (set) var salon:Salon!
    private (set) var parentManagedObjectContext:NSManagedObjectContext!
    private (set) var cancelled = true

    private let iterationWaitForSeconds: UInt64 = 5
    private let synchronisationQueue = dispatch_queue_create("com.AMCAldebaron.BQCoredataExportController", DISPATCH_QUEUE_SERIAL)
    private let namePrefix = "BQCoredataExportController"
    private let exportQueue:NSOperationQueue
    private let deletionRequestList:BQDeletionRequestList
    private let activeOperationsCounter = AMCThreadSafeCounter(initialValue: 0)
    private var nextRunTime = DISPATCH_TIME_NOW
    
    init(parentManagedObjectContext:NSManagedObjectContext, salon:Salon, startImmediately:Bool) {
        self.salon = salon
        self.parentManagedObjectContext = parentManagedObjectContext
        self.exportQueue = NSOperationQueue()
        self.exportQueue.name = namePrefix + "Queue"
        self.deletionRequestList = BQDeletionRequestList(parentManagedObjectContext: self.parentManagedObjectContext)
                
        if startImmediately {
            self.startExportIterations()
        }
    }
    /** Start iterating new export operations. Safe to call this multiple times because subsequent calls have no effect unless cancelled has been set (usually by a call to cancel) after the first call */
    func startExportIterations() {
        if !self.cancelled {
            // already running
            return
        }
        self.cancelled = false
        self.runExportIterationAfterWait(iterationWaitForSeconds)
    }
    /** Cancels all sub operations. The effect will not be immediate. Use startExportIterations when you want to restart */
    func cancel() {
        self.cancelled = true
        self.exportQueue.cancelAllOperations()
        self.deletionRequestList.cancel()
    }

    /** adds the export operation to the export queue and then calls itself until either the cancelled property becomes true or self is nil */
    private func runExportIterationAfterWait(waitForSeconds:UInt64) {
        weak var weakSelf = self
        if self.cancelled { return }
        let nextRunTime = dispatch_time(DISPATCH_TIME_NOW, Int64(waitForSeconds * NSEC_PER_SEC))
        dispatch_after(nextRunTime, synchronisationQueue) {
            if let strongSelf = weakSelf {
                defer {
                    print("Scheduling next iteration in \(waitForSeconds) seconds")
                    strongSelf.runExportIterationAfterWait(waitForSeconds)
                }
                // Handle deletions
                if strongSelf.activeOperationsCounter.count > 0 { return }
                print("Initiate processing of deletion request list")
                self.deletionRequestList.processList()
                
                // Handle insertions or modifications
                if strongSelf.activeOperationsCounter.incrementIfZero() {
                    print("Enquing new modify records operation")
                    let moc = strongSelf.parentManagedObjectContext
                    let newOperation = BQExportModifiedCoredataOperation(parentManagedObjectContext: moc, salonID: strongSelf.salon.objectID, activeOperationsCounter:self.activeOperationsCounter)
                    newOperation.completionBlock = { self.activeOperationsCounter.decrement() }
                    strongSelf.exportQueue.addOperation(newOperation)
                }
            }
        }
    }
}

// MARK:- Class BQExportModifiedCoredataOperation
private class BQExportModifiedCoredataOperation : NSOperation {
    private let synchronisationQueue = dispatch_queue_create("com.AMCAldebaron.BQExportModifiedCoredataOperation", DISPATCH_QUEUE_SERIAL)
    private let parentManagedObjectContext: NSManagedObjectContext
    private let modifedCoredata = Set<NSManagedObject>()
    private let salonID:NSManagedObjectID
    private var publicDatabase:CKDatabase!
    private let activeOperationsCounter: AMCThreadSafeCounter
    private var exportedRecords = Set<String>()
    
    init(parentManagedObjectContext:NSManagedObjectContext, salonID:NSManagedObjectID, activeOperationsCounter:AMCThreadSafeCounter) {
        self.parentManagedObjectContext = parentManagedObjectContext
        self.salonID = salonID
        self.activeOperationsCounter = activeOperationsCounter
        super.init()
        self.name = "BQExportModifiedCoredataOperation"
        self.qualityOfService = .Background
    }
    
    // MARK:- Main function for this operation
    override func main() {
        if self.cancelled { return }
        var recordsToSave = [CKRecord]()
        publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        let moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        moc.parentContext = parentManagedObjectContext
        moc.performBlockAndWait {
            recordsToSave = self.prepareCoredataObjectsForExportIfRequired(moc)
        }
        
        // Now create an operation to send the modified records to the cloud
        if self.cancelled || recordsToSave.count == 0 { return }
        let saveRecordsOperation = self.modifyRecordsOperation(moc, recordsToSave: recordsToSave)
        
        // Actually submit the operation
        self.activeOperationsCounter.increment()
        self.publicDatabase.addOperation(saveRecordsOperation)
    }
    
    // MARK:- Retry operation
    func retryOperation(operation:CKModifyRecordsOperation, waitInterval:Double) {
        let waitIntervalNanoseconds = Int64(waitInterval * 1000_000_000.0)
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, waitIntervalNanoseconds)
        dispatch_after(dispatchTime, self.synchronisationQueue) { () -> Void in
            self.activeOperationsCounter.increment()
            self.publicDatabase.addOperation(operation)
        }
    }
    
}
extension BQExportModifiedCoredataOperation {
    private func modifyRecordsOperation(moc:NSManagedObjectContext, recordsToSave:[CKRecord]) -> CKModifyRecordsOperation {
        let saveRecordsOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
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
            self.exportedRecords.insert(coredataID as! String)
        }
        
        // Set the records completion block
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

        // Set the completion block
        saveRecordsOperation.completionBlock = {
            self.activeOperationsCounter.decrement()
        }

        return saveRecordsOperation
    }
}
extension BQExportModifiedCoredataOperation {
    private func prepareCoredataObjectsForExportIfRequired(moc:NSManagedObjectContext) -> [CKRecord] {
        var recordsToSave = [CKRecord]()
        
        // Export the salon itself if required
        if self.cancelled { return recordsToSave}
        recordsToSave.append(self.prepareSalonForExportIfRequired(moc, salonID:self.salonID))
        
        // Gather all modifed customers
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareCustomersForExportIfRequired(moc, salonID: self.salonID))
        
        // Gather all modifed Service categories
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareServiceCategoriesForExportIfRequired(moc, salonID: self.salonID))
        
        // Gather all modified Services
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareServicesForExportIfRequired(moc, salonID: self.salonID))
        
        // Gather all modified Employees
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareEmployeesForExportIfRequired(moc, salonID: self.salonID))
        
        // Gather all modified SaleItems
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareSaleItemsForExportIfRequired(moc, salonID: self.salonID))
        
        // Gather all modified Sales
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareSalesForExportIfRequired(moc, salonID: self.salonID))
        
        // Gather all modified Appointments
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareAppointmentsForExportIfRequired(moc, salonID: self.salonID))
        
        return recordsToSave
    }
    
    private func prepareSalonForExportIfRequired(moc:NSManagedObjectContext, salonID:NSManagedObjectID) -> CKRecord {
        var cloudRecord: CKRecord?
        let salon = moc.objectWithID(self.salonID) as! Salon
        if salon.bqNeedsCoreDataExport?.boolValue == true {
            let icloudSalon = ICloudSalon(coredataSalon: salon)
            cloudRecord = icloudSalon.makeCloudKitRecord()
        }
        return cloudRecord!
    }
    
    private func prepareCustomersForExportIfRequired(moc:NSManagedObjectContext, salonID:NSManagedObjectID) -> [CKRecord] {
        let modifiedCustomers = Customer.customersMarkedForExport(moc) as Set<Customer>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedCustomers {
            let icloudObject = ICloudCustomer(coredataCustomer: modifiedObject, parentSalonID: self.salonID)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        return recordsToSave
    }
    private func prepareServiceCategoriesForExportIfRequired(moc:NSManagedObjectContext, salonID:NSManagedObjectID) -> [CKRecord] {
        let modifiedCategories = ServiceCategory.serviceCategoriesMarkedForExport(moc) as Set<ServiceCategory>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedCategories {
            let icloudObject = ICloudServiceCategory(coredataServiceCategory: modifiedObject, parentSalonID: salonID)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        return recordsToSave
    }
    private func prepareServicesForExportIfRequired(moc:NSManagedObjectContext, salonID:NSManagedObjectID) -> [CKRecord] {
        let modifiedServices = Service.servicesMarkedForExport(moc) as Set<Service>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedServices {
            let icloudObject = ICloudService(coredataService: modifiedObject, parentSalonID: salonID)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        return recordsToSave
    }
    private func prepareEmployeesForExportIfRequired(moc:NSManagedObjectContext, salonID:NSManagedObjectID) -> [CKRecord] {
        let modifiedEmployees = Employee.employeesMarkedForExport(moc) as Set<Employee>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedEmployees {
            let icloudObject = ICloudEmployee(coredataEmployee: modifiedObject, parentSalonID: salonID)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        return recordsToSave
    }
    private func prepareSaleItemsForExportIfRequired(moc:NSManagedObjectContext, salonID:NSManagedObjectID) -> [CKRecord] {
        let modifiedSaleItems = SaleItem.saleItemsMarkedForExport(moc) as Set<SaleItem>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedSaleItems {
            guard let _ = modifiedObject.sale?.fromAppointment else {
                continue
            }
            let icloudObject = ICloudSaleItem(coredataSaleItem: modifiedObject, parentSalonID: salonID)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        return recordsToSave
    }
    private func prepareSalesForExportIfRequired(moc:NSManagedObjectContext, salonID:NSManagedObjectID) -> [CKRecord] {
        let modifiedSales = Sale.salesMarkedForExport(moc) as Set<Sale>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedSales {
            guard let _ = modifiedObject.fromAppointment else {
                continue
            }
            let icloudObject = ICloudSale(coredataSale: modifiedObject, parentSalonID: salonID)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        return recordsToSave
    }
    private func prepareAppointmentsForExportIfRequired(moc:NSManagedObjectContext, salonID:NSManagedObjectID) -> [CKRecord] {
        let modifiedAppointments = Appointment.appointmentsMarkedForExport(moc) as Set<Appointment>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedAppointments {
            let icloudObject = ICloudAppointment(coredataAppointment: modifiedObject, parentSalonID: salonID)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        return recordsToSave
    }
}
