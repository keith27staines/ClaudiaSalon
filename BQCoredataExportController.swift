
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
@objc
class BQCoredataExportController : NSObject {
    var dataWasExported:(()->Void)?
    private (set) var parentMoc:NSManagedObjectContext!
    private (set) var cancelled = true

    private let iterationWaitForSeconds: UInt64 = 5
    private let synchronisationQueue = dispatch_queue_create("com.AMCAldebaron.BQCoredataExportController", DISPATCH_QUEUE_SERIAL)
    private let namePrefix = "BQCoredataExportController"
    private let exportQueue:NSOperationQueue
    private let activeOperationsCounter = AMCThreadSafeCounter(name:"Export Operations Counter",initialValue: 0)
    private var nextRunTime = DISPATCH_TIME_NOW
    private var iCloudContainerIdentifier:String!
    
    init(parentMoc:NSManagedObjectContext,iCloudContainerIdentifier:String,startProcessingImmediately:Bool) {
        self.iCloudContainerIdentifier = iCloudContainerIdentifier
        self.parentMoc = parentMoc
        self.exportQueue = NSOperationQueue()
        self.exportQueue.name = namePrefix + "Queue"
        super.init()
        
        if startProcessingImmediately {
            self.resumeExportIterations()
        } else {
            self.suspendExportIterations()
        }
    }
    
    func isSuspended() -> Bool {
        return self.cancelled
    }
    
    /** Start iterating new export operations. Safe to call this multiple times because subsequent calls have no effect unless cancelled has been set (usually by a call to cancel) after the first call */
    func resumeExportIterations() {
        if !self.cancelled {
            // already running
            return
        }
        self.cancelled = false
        self.runExportIterationAfterWait(iterationWaitForSeconds)
    }
    /** Cancels all sub operations. The effect will not be immediate. Use startExportIterations when you want to restart */
    func suspendExportIterations() {
        self.cancelled = true
        self.exportQueue.cancelAllOperations()
    }

    /** adds the export operation to the export queue and then calls itself until either the cancelled property becomes true or self is nil */
    private func runExportIterationAfterWait(waitForSeconds:UInt64) {
        weak var weakSelf = self
        if self.cancelled { return }
        let nextRunTime = dispatch_time(DISPATCH_TIME_NOW, Int64(waitForSeconds * NSEC_PER_SEC))
        dispatch_after(nextRunTime, synchronisationQueue) {
            if let strongSelf = weakSelf {
                
                // Handle modifications - only process if we can "gain the lock"
                if strongSelf.activeOperationsCounter.incrementIfZero() {
                    print("Running export iteration")
                    let newOperation = BQExportModifiedCoredataOperation(parentMoc: self.parentMoc,iCloudContainerIdentifier: self.iCloudContainerIdentifier,activeOperationsCounter:self.activeOperationsCounter)
                    newOperation.dataWasExported = self.dataWasExported
                    newOperation.completionBlock = {
                        self.activeOperationsCounter.decrement()
                    }
                    strongSelf.exportQueue.addOperation(newOperation)
                }
                print("Scheduling next iteration in \(waitForSeconds) seconds")
                strongSelf.runExportIterationAfterWait(waitForSeconds)
            }
        }
    }
}

// MARK:- Class BQExportModifiedCoredataOperation
private class BQExportModifiedCoredataOperation : NSOperation {
    var dataWasExported:(()->Void)?
    private let synchronisationQueue = dispatch_queue_create("com.AMCAldebaron.BQExportModifiedCoredataOperation", DISPATCH_QUEUE_SERIAL)

    private let modifedCoredata = Set<NSManagedObject>()
    private var publicDatabase:CKDatabase!
    private let activeOperationsCounter: AMCThreadSafeCounter
    private var exportedRecordsWithErrors = [String:NSError?]()
    private var coredataObjectsNeedingExport = [String:NSManagedObject]()
    private var salon:Salon!
    private var parentMoc:NSManagedObjectContext!
    private var workerMoc:NSManagedObjectContext!
    private var iCloudContainerIdentifier:String!

    init(parentMoc:NSManagedObjectContext,iCloudContainerIdentifier:String,activeOperationsCounter:AMCThreadSafeCounter) {
        self.activeOperationsCounter = activeOperationsCounter
        self.parentMoc = parentMoc
        super.init()
        self.name = "BQExportModifiedCoredataOperation"
        self.qualityOfService = .Background
        self.iCloudContainerIdentifier = iCloudContainerIdentifier
        self.publicDatabase = CKContainer(identifier: self.iCloudContainerIdentifier).publicCloudDatabase
    }
    
    // MARK:- Main function for this operation
    override func main() {
        if self.cancelled { return }
        self.workerMoc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.workerMoc.parentContext = self.parentMoc
        self.salon = Salon(moc: self.workerMoc)

        var recordsToSave = [CKRecord]()
        let moc = self.workerMoc
        moc.performBlockAndWait {
            recordsToSave = self.prepareCoredataObjectsForExportIfRequired()
        }
        if recordsToSave.count == 0 {
            return
        }
        
        // Now create an operation to send the modified records to the cloud
        if self.cancelled { return }
        let saveRecordsOperation = self.modifyRecordsOperation(recordsToSave)
        saveRecordsOperation.completionBlock = self.saveRecordsOperationComplete
        
        // Actually submit the operation
        self.activeOperationsCounter.increment()
        self.publicDatabase.addOperation(saveRecordsOperation)
    }
    func saveRecordsOperationComplete() -> Void {
        self.workerMoc.performBlockAndWait() {
            for (cloudID,error) in self.exportedRecordsWithErrors {
                let managedObject = self.coredataObjectsNeedingExport[cloudID]! as! BQExportable
                if error == nil {
                    managedObject.bqNeedsCoreDataExport = NSNumber(bool: false)
                } else {
                    print("managed object failed to export with error \(error)")
                }
            }
            do {
                if self.workerMoc.hasChanges {
                    try self.workerMoc.save()
                    if let callback = self.dataWasExported {
                        callback()
                    }
                }
            } catch {
                print(error)
            }
        }
        self.activeOperationsCounter.decrement()
    }
    
    // MARK:- Retry operation
    func retryOperationOnPublicDatabase(operation:CKModifyRecordsOperation, waitInterval:Double) {
        let waitIntervalNanoseconds = Int64(waitInterval * 1_000_000_000.0)
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, waitIntervalNanoseconds)
        dispatch_after(dispatchTime, self.synchronisationQueue) { () -> Void in
            self.activeOperationsCounter.increment()
            self.publicDatabase.addOperation(operation)
        }
    }
}

// MARK:- create a CKModifyRecordsOperation to update the cloud
extension BQExportModifiedCoredataOperation {
    private func modifyRecordsOperation(recordsToSave:[CKRecord]) -> CKModifyRecordsOperation {
        let saveRecordsOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
        saveRecordsOperation.savePolicy = .ChangedKeys
        
        // set the per-record block
        saveRecordsOperation.perRecordCompletionBlock = {(record,error)-> Void in
            guard let record = record else {
                return
            }
            dispatch_sync(self.synchronisationQueue) {
                let cloudID = record.recordID.recordName
                var userInfo = [NSObject:AnyObject]()
                userInfo["record"] = record
                userInfo["error"] = error
                NSNotificationCenter.defaultCenter().postNotificationName("appointmentWasModified", object: self, userInfo: userInfo)
                self.exportedRecordsWithErrors[cloudID] = error
            }
        }
        
        // Set the records completion block
        saveRecordsOperation.modifyRecordsCompletionBlock = {(saveRecords, deleteRecords, error)-> Void in
            if let error = error {
                switch error.code {
                case CKErrorCode.LimitExceeded.rawValue:
                    /* This operation was "too big", so recurse down to
                    ever smaller operations until they succeed or
                    fail for a different reason
                    */
                    
                    // Divide the recordIDs array into two halves
                    guard let records = saveRecordsOperation.recordsToSave else {
                        preconditionFailure("Expected records not to be nil")
                    }
                    let n = records.count / 2
                    var firstHalfRecords = [CKRecord]()
                    var secondHalfRecords = [CKRecord]()
                    for index in records.indices {
                        if index <= n {
                            firstHalfRecords.append(records[index])
                        } else {
                            secondHalfRecords.append(records[index])
                        }
                    }
                    // new operations for first half of records
                    let firstHalfOperation = self.modifyRecordsOperation(firstHalfRecords)
                    firstHalfOperation.completionBlock = self.saveRecordsOperationComplete
                    
                    // new operation for second half
                    let secondHalfOperation = self.modifyRecordsOperation(secondHalfRecords)
                    secondHalfOperation.completionBlock = self.saveRecordsOperationComplete
                    secondHalfOperation.addDependency(firstHalfOperation)

                    // add the sub operations to the queue
                    self.activeOperationsCounter.increment()
                    self.publicDatabase.addOperation(firstHalfOperation)
                    self.activeOperationsCounter.increment()
                    self.publicDatabase.addOperation(secondHalfOperation)
                    return
                case CKErrorCode.PartialFailure.rawValue:
                    print(error)
                case CKErrorCode.ZoneBusy.rawValue,
                CKErrorCode.RequestRateLimited.rawValue,
                CKErrorCode.ServiceUnavailable.rawValue:
                    // Transient failure - can retry this operation after a suitable delay
                    let retryAfter = error.userInfo["CKErrorRetryAfterKey"]!.doubleValue
                    self.retryOperationOnPublicDatabase(saveRecordsOperation, waitInterval: retryAfter)
                default:
                    // Operation failed unrecoverably so nothing we can do except figure out the cause
                    print("saveRecordsOperation failed unrecoverably")
                }
            }
        }
        return saveRecordsOperation
    }
}
// MARK:- prepare modified coredata objects for export to cloud
extension BQExportModifiedCoredataOperation {
    private func prepareCoredataObjectsForExportIfRequired() -> [CKRecord] {
        var recordsToSave = [CKRecord]()
        
        // Export the salon itself if required
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareSalonForExportIfRequired(self.salon))
        if recordsToSave.count > 0 {
            return recordsToSave
        }

        // Gather all modified Employees
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareEmployeesForExportIfRequired(self.salon))
        
        // Gather all modifed customers
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareCustomersForExportIfRequired(self.salon))
        
        // Gather all modifed Service categories
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareServiceCategoriesForExportIfRequired(self.salon))
        
        // Gather all modified Services
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareServicesForExportIfRequired(self.salon))
        
        // Gather all modified SaleItems
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareSaleItemsForExportIfRequired(self.salon))
        
        // Gather all modified Sales
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareSalesForExportIfRequired(self.salon))
        
        // Gather all modified Appointments
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareAppointmentsForExportIfRequired(self.salon))
        
        return recordsToSave
    }
    
    private func prepareSalonForExportIfRequired(salon:Salon) -> [CKRecord] {
        var recordsToSave = [CKRecord]()
        var cloudSalonRecord: CKRecord?
        
        let anonCustomer = salon.anonymousCustomer
        if salon.bqNeedsCoreDataExport?.boolValue == true {
            dispatch_sync(self.synchronisationQueue) {
                let icloudSalon = ICloudSalon(coredataSalon: salon)
                var cloudID = salon.bqCloudID!
                self.coredataObjectsNeedingExport[cloudID] = salon
                cloudSalonRecord = icloudSalon.makeCloudKitRecord()
                recordsToSave.append(cloudSalonRecord!)
                cloudID = anonCustomer!.bqCloudID!
                self.coredataObjectsNeedingExport[cloudID] = salon
                let cloudCustomer = ICloudCustomer(coredataCustomer: anonCustomer!, parentSalonID: salon.objectID)
                recordsToSave.append(cloudCustomer.makeCloudKitRecord())
            }
        }
        return recordsToSave
    }
    
    private func prepareCustomersForExportIfRequired(salon:Salon) -> [CKRecord] {
        let moc = salon.managedObjectContext!
        let modifiedCustomers = Customer.customersMarkedForExport(moc) as Set<Customer>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedCustomers {
            dispatch_sync(self.synchronisationQueue) {
                let icloudObject = ICloudCustomer(coredataCustomer: modifiedObject, parentSalonID: salon.objectID)
                let cloudID = modifiedObject.bqCloudID!
                self.coredataObjectsNeedingExport[cloudID] = modifiedObject
                let cloudRecord = icloudObject.makeCloudKitRecord()
                recordsToSave.append(cloudRecord)
            }
        }
        return recordsToSave
    }
    private func prepareServiceCategoriesForExportIfRequired(salon:Salon) -> [CKRecord] {
        let moc = salon.managedObjectContext!
        let modifiedCategories = ServiceCategory.serviceCategoriesMarkedForExport(moc) as Set<ServiceCategory>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedCategories {
            dispatch_sync(self.synchronisationQueue) {
                let icloudObject = ICloudServiceCategory(coredataServiceCategory: modifiedObject, parentSalonID: salon.objectID)
                let cloudID = modifiedObject.bqCloudID!
                self.coredataObjectsNeedingExport[cloudID] = modifiedObject
                let cloudRecord = icloudObject.makeCloudKitRecord()
                recordsToSave.append(cloudRecord)
            }
        }
        return recordsToSave
    }
    private func prepareServicesForExportIfRequired(salon:Salon) -> [CKRecord] {
        let moc = salon.managedObjectContext!
        let modifiedServices = Service.servicesMarkedForExport(moc) as Set<Service>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedServices {
            dispatch_sync(self.synchronisationQueue) {
                let icloudObject = ICloudService(coredataService: modifiedObject, parentSalonID: salon.objectID)
                let cloudID = modifiedObject.bqCloudID!
                self.coredataObjectsNeedingExport[cloudID] = modifiedObject
                let cloudRecord = icloudObject.makeCloudKitRecord()
                recordsToSave.append(cloudRecord)
            }
        }
        return recordsToSave
    }
    private func prepareEmployeesForExportIfRequired(salon:Salon) -> [CKRecord] {
        let moc = salon.managedObjectContext!
        let modifiedEmployees = Employee.employeesMarkedForExport(moc) as Set<Employee>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedEmployees {
            dispatch_sync(self.synchronisationQueue) {
                let icloudObject = ICloudEmployee(coredataEmployee: modifiedObject, parentSalonID: salon.objectID)
                let cloudID = modifiedObject.bqCloudID!
                self.coredataObjectsNeedingExport[cloudID] = modifiedObject
                let cloudRecord = icloudObject.makeCloudKitRecord()
                recordsToSave.append(cloudRecord)
            }
        }
        return recordsToSave
    }
    private func prepareSaleItemsForExportIfRequired(salon:Salon) -> [CKRecord] {
        let moc = salon.managedObjectContext!
        let modifiedSaleItems = SaleItem.saleItemsMarkedForExport(moc) as Set<SaleItem>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedSaleItems {
            // Exclude stand-alone sales. Only sales connected to appointments are of interest
            if let sale = modifiedObject.sale {
                if sale.fromAppointment == nil {
                    // This is a stand-alone sale, not connected to an appointment
                    continue
                }
            }
            dispatch_sync(self.synchronisationQueue) {
                let icloudObject = ICloudSaleItem(coredataSaleItem: modifiedObject, parentSalonID: salon.objectID)
                let cloudID = modifiedObject.bqCloudID!
                self.coredataObjectsNeedingExport[cloudID] = modifiedObject
                let cloudRecord = icloudObject.makeCloudKitRecord()
                recordsToSave.append(cloudRecord)
            }
        }
        return recordsToSave
    }
    private func prepareSalesForExportIfRequired(salon:Salon) -> [CKRecord] {
        let moc = salon.managedObjectContext!
        let modifiedSales = Sale.salesMarkedForExport(moc) as Set<Sale>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedSales {
            guard let _ = modifiedObject.fromAppointment else {
                continue
            }
            dispatch_sync(self.synchronisationQueue) {
                let icloudObject = ICloudSale(coredataSale: modifiedObject, parentSalonID: salon.objectID)
                let cloudID = modifiedObject.bqCloudID!
                self.coredataObjectsNeedingExport[cloudID] = modifiedObject
                let cloudRecord = icloudObject.makeCloudKitRecord()
                recordsToSave.append(cloudRecord)
            }
        }
        return recordsToSave
    }
    private func prepareAppointmentsForExportIfRequired(salon:Salon) -> [CKRecord] {
        let moc = self.workerMoc!
        let modifiedAppointments = Appointment.appointmentsMarkedForExport(moc) as Set<Appointment>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedAppointments {
            dispatch_sync(self.synchronisationQueue) {
                let icloudObject = ICloudAppointment(coredataAppointment: modifiedObject, parentSalonID: salon.objectID)
                let cloudID = modifiedObject.bqCloudID!
                self.coredataObjectsNeedingExport[cloudID] = modifiedObject
                let cloudRecord = icloudObject.makeCloudKitRecord()
                recordsToSave.append(cloudRecord)
            }
        }
        return recordsToSave
    }
}
