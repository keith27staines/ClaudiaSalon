
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
    let iterationWaitForSeconds: UInt64 = 5
    private let synchronisationQueue = dispatch_queue_create("com.AMCAldebaron.BQCoredataExportController", DISPATCH_QUEUE_SERIAL)

    let namePrefix = "BQCoredataExportController"
    let exportQueue:NSOperationQueue
    let parentManagedObjectContext:NSManagedObjectContext!
    let salon:Salon!
    let deletionRequestList:BQDeletionRequestList
    private let activeOperationsCounter = AMCThreadSafeCounter(initialValue: 0)

    private var cancelled = true
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
    func cancel() {
        self.cancelled = true
        for operation in self.exportQueue.operations {
            operation.cancel()
        }
        self.deletionRequestList.cancel()
    }

    /** adds the export operation to the export queue and then calls itself until either the cancelled property becomes true or self is nil */
    private func runExportIterationAfterWait(waitForSeconds:UInt64) {
        weak var weakSelf = self
        if self.cancelled { return }
        let nextRunTime = dispatch_time(DISPATCH_TIME_NOW, Int64(waitForSeconds * NSEC_PER_SEC))
        dispatch_after(nextRunTime, synchronisationQueue) {
            if let strongSelf = weakSelf {
                // First, handle any deletions
                print("Initiate processing of deletion request list")
                self.deletionRequestList.processList()
                
                // Next, handle any insertions or modifications
                if strongSelf.activeOperationsCounter.count == 0 {
                    print("Enquing new modify records operation")
                    let newOperation = BQExportModifiedCoredataOperation(parentManagedObjectContext: strongSelf.parentManagedObjectContext, salon: strongSelf.salon, activeOperationsCounter:self.activeOperationsCounter)
                    newOperation.completionBlock = {
                        self.activeOperationsCounter.decrement()
                    }
                    self.activeOperationsCounter.increment()
                    strongSelf.exportQueue.addOperation(newOperation)
                }
                print("Scheduling next iteration")
                strongSelf.runExportIterationAfterWait(waitForSeconds)
            }
        }
    }
}

// MARK:- Class BQExportModifiedCoredataOperation
class BQExportModifiedCoredataOperation : NSOperation {
    private let synchronisationQueue = dispatch_queue_create("com.AMCAldebaron.BQExportModifiedCoredataOperation", DISPATCH_QUEUE_SERIAL)
    let parentManagedObjectContext: NSManagedObjectContext
    let modifedCoredata = Set<NSManagedObject>()
    let salon:Salon
    var publicDatabase:CKDatabase!
    let activeOperationsCounter: AMCThreadSafeCounter
    var exportedRecords = Set<String>()
    
    init(parentManagedObjectContext:NSManagedObjectContext, salon:Salon, activeOperationsCounter:AMCThreadSafeCounter) {
        self.parentManagedObjectContext = parentManagedObjectContext
        self.salon = salon
        self.activeOperationsCounter = activeOperationsCounter
        super.init()
        self.name = "BQExportModifiedCoredataOperation"
        self.qualityOfService = .Background
    }

    // MARK:- Main function for this operation
    override func main() {
        if self.cancelled { return }
        let privateManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        privateManagedObjectContext.parentContext = parentManagedObjectContext
        publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
        var recordsToSave = [CKRecord]()
        
        // Export the salon itself if required
        if salon.bqNeedsCoreDataExport?.boolValue == true {
            let icloudSalon = ICloudSalon(coredataSalon: salon)
            let cloudRecord = icloudSalon.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Gather all modifed customers
        if self.cancelled { return }
        let modifiedCustomers = Customer.customersMarkedForExport(privateManagedObjectContext) as Set<Customer>
        for modifiedObject in modifiedCustomers {
            let icloudObject = ICloudCustomer(coredataCustomer: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }

        // Gather all modifed Service categories
        if self.cancelled { return }
        let modifiedServiceCategories = ServiceCategory.serviceCategoriesMarkedForExport(privateManagedObjectContext) as Set<ServiceCategory>
        for modifiedObject in modifiedServiceCategories {
            let icloudObject = ICloudServiceCategory(coredataServiceCategory: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Gather all modified Services
        if self.cancelled { return }
        let modifiedServices = Service.servicesMarkedForExport(privateManagedObjectContext) as Set<Service>
        for modifiedObject in modifiedServices {
            let icloudObject = ICloudService(coredataService: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Gather all modified Employees
        if self.cancelled { return }
        let modifiedEmployees = Employee.employeesMarkedForExport(privateManagedObjectContext) as Set<Employee>
        for modifiedObject in modifiedEmployees {
            let icloudObject = ICloudEmployee(coredataEmployee: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Gather all modified SaleItems
        if self.cancelled { return }
        let modifiedSaleItems = SaleItem.saleItemsMarkedForExport(privateManagedObjectContext) as Set<SaleItem>
        for modifiedObject in modifiedSaleItems {
            guard modifiedObject.sale?.fromAppointment != nil else {
                continue
            }
            let icloudObject = ICloudSaleItem(coredataSaleItem: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Gather all modified Sales
        if self.cancelled { return }
        let modifiedSales = Sale.salesMarkedForExport(privateManagedObjectContext) as Set<Sale>
        for modifiedObject in modifiedSales {
            guard modifiedObject.fromAppointment != nil else {
                continue
            }
            let icloudObject = ICloudSale(coredataSale: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Gather all modified Appointments
        if self.cancelled { return }
        let modifiedAppointments = Appointment.appointmentsMarkedForExport(privateManagedObjectContext) as Set<Appointment>
        for modifiedObject in modifiedAppointments {
            let icloudObject = ICloudAppointment(coredataAppointment: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Now save the modified records
        if self.cancelled { return }

        if recordsToSave.count == 0 {
            return
        }
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