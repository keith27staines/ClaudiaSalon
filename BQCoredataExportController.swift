
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
        let nextRunTime = dispatch_time(DISPATCH_TIME_NOW, Int64(30 * NSEC_PER_SEC))
        dispatch_after(nextRunTime, dispatch_get_main_queue()) { () -> Void in
            if let strongSelf = weakSelf {
                strongSelf.exportQueue.addOperation(self.exportOperation)
                strongSelf.runExportIteration()
                if !(strongSelf.exportOperation.executing || strongSelf.exportOperation.ready) {
                    strongSelf.exportQueue.addOperation(strongSelf.exportOperation)
                }
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
            let icloudObject = ICloudSaleItem(coredataSaleItem: modifiedObject, parentSalon: self.salon)
            let cloudRecord = icloudObject.makeFirstCloudKitRecord()
            recordsToSave.append(cloudRecord)
        }
        
        // Gather all modified Sales
        if self.cancelled { return }
        let modifiedSales = Sale.salesMarkedForExport(self.managedObjectContext) as Set<Sale>
        for modifiedObject in modifiedSales {
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

// MARK:- Extensions on exportable managed objects
extension Customer {
    class func customersMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<Customer> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"Customer")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [Customer])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<Customer>()
        }
    }
}
extension Employee {
    class func employeesMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<Employee> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"Employee")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [Employee])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<Employee>()
        }
    }
}
extension Service {
    class func servicesMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<Service> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"Service")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [Service])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<Service>()
        }
    }
}
extension ServiceCategory {
    class func serviceCategoriesMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<ServiceCategory> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"ServiceCategory")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [ServiceCategory])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<ServiceCategory>()
        }
    }
}
extension Appointment {
    class func appointmentsMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<Appointment> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"Appointment")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [Appointment])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<Appointment>()
        }
    }
}
extension SaleItem {
    class func saleItemsMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<SaleItem> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"SaleItem")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [SaleItem])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<SaleItem>()
        }
    }
}
extension Sale {
    class func salesMarkedForExport(managedObjectContext:NSManagedObjectContext) -> Set<Sale> {
        let predicate = NSPredicate(format: "bqNeedsCoreDataExport = %@", true)
        let fetchRequest = NSFetchRequest(entityName:"Sale")
        fetchRequest.predicate = predicate
        do {
            let fetchedResults = try managedObjectContext.executeFetchRequest(fetchRequest)
            return Set(fetchedResults as! [Sale])
        } catch {
            assertionFailure("Unable to fetch objects marked for export")
            return Set<Sale>()
        }
    }
}
// MARK:- NSManagedObject extension
extension NSManagedObject {
    func markAsExported() {
        switch self.className {
        case "Salon":
            let salon = self as! Salon
            salon.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "Customer":
            let customer = self as! Customer
            customer.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "Employee":
            let employee = self as! Employee
            employee.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "Service":
            let service = self as! Service
            service.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "ServiceCategory":
            let serviceCategory = self as! ServiceCategory
            serviceCategory.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "Appointment":
            let appointment = self as! Appointment
            appointment.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "Sale":
            let sale = self as! Sale
            sale.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        case "SaleItem":
            let saleItem = self as! SaleItem
            saleItem.bqNeedsCoreDataExport = NSNumber(bool: false)
            break
        default:
            break
        }
    }
}
// MARK:- NSManagedObjectContext extension
extension NSManagedObjectContext {
    func objectForIDString(coredataIDString:String) -> NSManagedObject {
        guard let coordinator = self.persistentStoreCoordinator else {
            preconditionFailure("The managed object context doesn't have a persistent store coordinator")
        }
        guard let uriRepresentation = NSURL(string: coredataIDString) else {
            preconditionFailure("Unable to construct a URL from the string \(coredataIDString)")
        }
        guard let managedObjectID = coordinator.managedObjectIDForURIRepresentation(uriRepresentation) else {
            preconditionFailure("The persistent store coordinate didn't return an objectID for the URL representation")
        }
        return self.objectWithID(managedObjectID)
    }
}
