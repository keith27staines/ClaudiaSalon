
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
    private (set) var salonDocument:AMCSalonDocument!
    private (set) var salon:Salon!
    private (set) var parentManagedObjectContext:NSManagedObjectContext!
    private (set) var cancelled = true

    private let iterationWaitForSeconds: UInt64 = 5
    private let synchronisationQueue = dispatch_queue_create("com.AMCAldebaron.BQCoredataExportController", DISPATCH_QUEUE_SERIAL)
    private let namePrefix = "BQCoredataExportController"
    private let exportQueue:NSOperationQueue
    private let deletionRequestList:BQDeletionRequestList
    private let activeOperationsCounter = AMCThreadSafeCounter(name:"Export Operations Counter",initialValue: 0)
    private var nextRunTime = DISPATCH_TIME_NOW
    
    init(salonDocument:AMCSalonDocument, startImmediately:Bool) {
        self.salonDocument = salonDocument
        self.salon = salonDocument.salon
        self.parentManagedObjectContext = self.salonDocument.managedObjectContext
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
                
                // Handle deletions
                self.deletionRequestList.processList()
                
                // Handle modifications - only process if we can "gain the lock"
                if strongSelf.activeOperationsCounter.incrementIfZero() {
                    print("Running export iteration")
                    let salonDocument = strongSelf.salonDocument
                    let newOperation = BQExportModifiedCoredataOperation(salonDocument: salonDocument, activeOperationsCounter:self.activeOperationsCounter)
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
    private let synchronisationQueue = dispatch_queue_create("com.AMCAldebaron.BQExportModifiedCoredataOperation", DISPATCH_QUEUE_SERIAL)
    private let parentManagedObjectContext: NSManagedObjectContext
    private let modifedCoredata = Set<NSManagedObject>()
    private let salonID:NSManagedObjectID
    private var publicDatabase:CKDatabase!
    private let activeOperationsCounter: AMCThreadSafeCounter
    private var exportedRecordsWithErrors = [String:NSError?]()
    private var privateMoc: NSManagedObjectContext?
    private var coredataObjectsNeedingExport = [String:NSManagedObject]()
    private let salonDocument:AMCSalonDocument

    init(salonDocument:AMCSalonDocument, activeOperationsCounter:AMCThreadSafeCounter) {
        self.salonDocument = salonDocument
        self.parentManagedObjectContext = salonDocument.managedObjectContext!
        self.activeOperationsCounter = activeOperationsCounter
        self.salonID = NSManagedObjectID()
        super.init()
        self.parentManagedObjectContext.performBlockAndWait() {
            self.salonID = self.salonDocument.salon.objectID
        }
        self.name = "BQExportModifiedCoredataOperation"
        self.qualityOfService = .Background
    }
    
    // MARK:- Main function for this operation
    override func main() {
        if self.cancelled { return }
        var recordsToSave = [CKRecord]()
        publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        self.privateMoc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        let moc = self.privateMoc!
        moc.parentContext = parentManagedObjectContext
        moc.performBlockAndWait {
            recordsToSave = self.prepareCoredataObjectsForExportIfRequired(moc)
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
        if let privateMoc = self.privateMoc {
            privateMoc.performBlockAndWait() {
                for (coredataID,error) in self.exportedRecordsWithErrors {
                    let managedObject = self.coredataObjectsNeedingExport[coredataID]!
                    if error == nil {
                        managedObject.markAsExported()
                    } else {
                        print("managed object failed to export with error \(error)")
                    }
                }
                do {
                    if privateMoc.hasChanges {
                        try privateMoc.save()
                        dispatch_sync(dispatch_get_main_queue()) {
                            self.salonDocument.saveDocument(self)
                        }
                    }
                } catch {
                    print(error)
                }
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
            guard let coredataID = record["coredataID"] as? String  else {
                fatalError("This record was expected to have a coredata id but none found")
            }
            dispatch_sync(self.synchronisationQueue) {
                self.exportedRecordsWithErrors[coredataID] = error
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
                    fatalError("saveRecordsOperation failed unrecoverably")
                }
            }
        }
        return saveRecordsOperation
    }
}
// MARK:- prepare modified coredata objects for export to cloud
extension BQExportModifiedCoredataOperation {
    private func prepareCoredataObjectsForExportIfRequired(moc:NSManagedObjectContext) -> [CKRecord] {
        var recordsToSave = [CKRecord]()
        
        // Export the salon itself if required
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareSalonForExportIfRequired(moc, salonID:self.salonID))
        if recordsToSave.count > 0 {
            return recordsToSave
        }

        // Gather all modified Employees
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareEmployeesForExportIfRequired(moc, salonID: self.salonID))
        
        // Gather all modifed customers
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareCustomersForExportIfRequired(moc, salonID: self.salonID))
        
        // Gather all modifed Service categories
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareServiceCategoriesForExportIfRequired(moc, salonID: self.salonID))
        
        // Gather all modified Services
        if self.cancelled { return recordsToSave}
        recordsToSave.appendContentsOf(self.prepareServicesForExportIfRequired(moc, salonID: self.salonID))
        
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
    
    private func prepareSalonForExportIfRequired(moc:NSManagedObjectContext, salonID:NSManagedObjectID) -> [CKRecord] {
        var recordsToSave = [CKRecord]()
        var cloudRecord: CKRecord?
        let salon = moc.objectWithID(self.salonID) as! Salon
        if salon.bqNeedsCoreDataExport?.boolValue == true {
            dispatch_sync(self.synchronisationQueue) {
                let coredataID = salon.objectID.URIRepresentation().absoluteString
                self.coredataObjectsNeedingExport[coredataID] = salon
            }
            let icloudSalon = ICloudSalon(coredataSalon: salon)
            cloudRecord = icloudSalon.makeCloudKitRecord()
            recordsToSave.append(cloudRecord!)
        }
        return recordsToSave
    }
    
    private func prepareCustomersForExportIfRequired(moc:NSManagedObjectContext, salonID:NSManagedObjectID) -> [CKRecord] {
        let modifiedCustomers = Customer.customersMarkedForExport(moc) as Set<Customer>
        var recordsToSave = [CKRecord]()
        for modifiedObject in modifiedCustomers {
            dispatch_sync(self.synchronisationQueue) {
                let coredataID = modifiedObject.objectID.URIRepresentation().absoluteString
                self.coredataObjectsNeedingExport[coredataID] = modifiedObject
            }
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
            dispatch_sync(self.synchronisationQueue) {
                let coredataID = modifiedObject.objectID.URIRepresentation().absoluteString
                self.coredataObjectsNeedingExport[coredataID] = modifiedObject
            }
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
            dispatch_sync(self.synchronisationQueue) {
                let coredataID = modifiedObject.objectID.URIRepresentation().absoluteString
                self.coredataObjectsNeedingExport[coredataID] = modifiedObject
            }
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
            dispatch_sync(self.synchronisationQueue) {
                let coredataID = modifiedObject.objectID.URIRepresentation().absoluteString
                self.coredataObjectsNeedingExport[coredataID] = modifiedObject
            }
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
            // Exclude stand-alone sales. Only sales connected to appointments are of interest
            if let sale = modifiedObject.sale {
                if sale.fromAppointment == nil {
                    // This is a stand-alone sale, not connected to an appointment
                    continue
                }
            }
            dispatch_sync(self.synchronisationQueue) {
                let coredataID = modifiedObject.objectID.URIRepresentation().absoluteString
                self.coredataObjectsNeedingExport[coredataID] = modifiedObject
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
            dispatch_sync(self.synchronisationQueue) {
                let coredataID = modifiedObject.objectID.URIRepresentation().absoluteString
                self.coredataObjectsNeedingExport[coredataID] = modifiedObject
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
            dispatch_sync(self.synchronisationQueue) {
                let coredataID = modifiedObject.objectID.URIRepresentation().absoluteString
                self.coredataObjectsNeedingExport[coredataID] = modifiedObject
            }
            let icloudObject = ICloudAppointment(coredataAppointment: modifiedObject, parentSalonID: salonID)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        return recordsToSave
    }
}
