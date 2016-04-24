//
//  BQFirstExtractController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

// MARK:- Helper functions
func uidStringFromManagedObject(managedObject:NSManagedObject) -> String {
    return managedObject.objectID.URIRepresentation().absoluteString
}

// MARK:- class BQExtractModelDelegate
protocol BQFirstExtractControllerDelegate {
    func coredataRecordWasExtracted(sender:AnyObject, recordType:String, extractCount: Int, total: Int)
    func fullCoredataExtractWasCompleted(sender:AnyObject)
}
// MARK:- class BQFirstExtractController
class BQFirstExtractController {
    var delegate: BQFirstExtractControllerDelegate?
    var salonDocument: AMCSalonDocument!
    var salon: Salon!
    var salonID: NSManagedObjectID!
    let icloudContainer = CKContainer.defaultContainer()
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    private let synchronisationQueue = dispatch_queue_create("com.AMCAldebaron.BQCoredataExportController", DISPATCH_QUEUE_SERIAL)
    var extractedCustomerCount = 0
    var extractedEmployeesCount = 0
    var extractedServiceCategoriesCount = 0
    var extractedServicesCount = 0
    var extractedAppointmentsCount = 0
    var extractedSalesCount = 0
    var extractedSaleItemsCount = 0
    
    var totalCustomersToProcess = 0
    var totalEmployeesToProcess = 0
    var totalServiceCategoriesToProcess = 0
    var totalServicesToProcess = 0
    var totalAppointmentsToProcess = 0
    var totalSalesToProcess = 0
    var totalSaleItemsToProcess = 0
    
    var allCoredataCustomers = [Customer]()
    var allCoredataEmployees = [Employee]()
    var allCoredataServiceCategories = [ServiceCategory]()
    var allCoredataServices = [Service]()
    var allUnexpiredCoredataAppointments = [Appointment]()
    var allCoredataSales = [Sale]()
    var allCoredataSaleItems = [SaleItem]()
    
    var coredataCustomersDictionary = [String:Customer]()
    var coredataEmployeeDictionary = [String:Employee]()
    var coredataServiceCategoriesDictionary = [String:ServiceCategory]()
    var coredataServicesDictionary = [String:Service]()
    var coredataAppointmentsDictionary = [String:Appointment]()
    
    var cloudSalonRecord: CKRecord?
    var cloudSalonReference: CKReference?
    let parentManagedObjectContext:NSManagedObjectContext
    var moc: NSManagedObjectContext!
    
    init(salonDocument:AMCSalonDocument) {
        self.salonDocument = salonDocument
        self.parentManagedObjectContext = salonDocument.managedObjectContext!
        self.salonID = salonDocument.salon.objectID
        dispatch_sync(self.synchronisationQueue) {
            self.moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            self.moc.parentContext = self.parentManagedObjectContext
            self.moc.performBlockAndWait() {
                self.salon = self.moc.objectWithID(self.salonID) as! Salon
            }
        }
    }
    
    // MARK: Prepare coredata for clean extract
    func resetDataExtract() {
        // Delete Salon (this should cascade deletes all the way down)
        //deleteAllIcloudData()
        prepareCoredataRecordsReadyForFirstExport()
    }

    // Delete all existing extracted records from icloud
    func deleteAllIcloudData() {
        guard let _ = self.salonDocument.salon.bqMetadata else {
            print("deleteAllIcloudData - No salon data to delete!")
            return
        }
        let icloudSalon = ICloudSalon(coredataSalon: self.salon)
        publicDatabase.deleteRecordWithID(icloudSalon.recordID!, completionHandler: { (record, error) -> Void in
            if error != nil {
                // Failed to delete the salon?
                assertionFailure("Failed to delete the parent salon")
            } else {
                // Delete worked - check to make sure all child records also deleted
            }
        })
    }
    
    // Prepare coredata records for extract
    func prepareCoredataRecordsReadyForFirstExport() {
        var readyForExport = 0
        var others = 0
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)) {
            self.moc.performBlockAndWait() {
                self.salonDocument.salon.bqNeedsCoreDataExport = true
                self.salonDocument.salon.bqMetadata = nil;
                self.prepareAllCustomersForCoredataExport()
                self.prepareAllEmployeesForCoredataExport()
                self.prepareAllServiceCategoriesForCoredataExport()
                self.prepareAllServicesForCoredataExport()
                self.prepareAllAppointmentsForCoredataExport()
                for saleItem in SaleItem.allObjectsWithMoc(self.moc) as! [SaleItem] {
                    if saleItem.bqNeedsCoreDataExport!.boolValue == true {
                        readyForExport += 1
                    } else {
                        others += 1
                    }
                }
                do {
                    try self.moc.save()
                } catch {
                    print("Unable to save moc \(error)")
                }
                dispatch_sync(dispatch_get_main_queue()) {
                    self.salonDocument.saveDocument(self)
                    print("Sale Items ready for export = \(readyForExport)")
                    print("Sale Items not needing export = \(others)")
                    print("reset finished")
                }
            }
        }
    }
    
    // MARK:- Extract data
    func extractData() {
        if moc == nil { preconditionFailure("No managed object context") }
        // Create operation to extract the coredata salon
        let salonOperation = extractSalonOperation()
        salonOperation.completionBlock = { () -> Void in
            // Prepare the salon's child data for export
            self.prepareAllCustomersForCoredataExport()
            self.prepareAllEmployeesForCoredataExport()
            self.prepareAllServiceCategoriesForCoredataExport()
            self.prepareAllServicesForCoredataExport()
            self.prepareAllAppointmentsForCoredataExport()  // Also prepares child sale and saleItems for export
            
            let customerRecords = self.makeExportRecordsForCoredataCustomers()
            let employeeRecords = self.makeExportRecordsForCoredataEmployees()
            let serviceCategoryRecords = self.makeExportRecordsForCoredataServiceCategies()
            
            // Create operations to do the export
            let customersOperation = self.saveRecordsOperation(customerRecords)
            let employeesOperation = self.saveRecordsOperation(employeeRecords)
            let serviceCategoriesOperation = self.saveRecordsOperation(serviceCategoryRecords)
            
            // Make child record operations dependent on the salon operation
            customersOperation.addDependency(salonOperation)
            employeesOperation.addDependency(salonOperation)
            serviceCategoriesOperation.addDependency(salonOperation)
            
            // Execute the operations
            self.publicDatabase.addOperation(customersOperation)
            self.publicDatabase.addOperation(employeesOperation)
            self.publicDatabase.addOperation(serviceCategoriesOperation)
        }
        self.publicDatabase.addOperation(salonOperation)
    }
    
    // MARK:- create arrays of coredata objects requiring export to icloud
    func coredataCustomersNeedingExport() -> [Customer] {
        return allCoredataCustomers.filter { (customer) -> Bool in
            return (customer.bqNeedsCoreDataExport?.boolValue == true)
        }
    }
    func coredataEmployeesNeedingExport() -> [Employee] {
        return allCoredataEmployees.filter({ (employee) -> Bool in
            return (employee.bqNeedsCoreDataExport?.boolValue == true )
        })
    }
    func coredataServiceCategoriesNeedingExport() -> [ServiceCategory] {
        return allCoredataServiceCategories.filter({ (serviceCategory) -> Bool in
            return (serviceCategory.bqNeedsCoreDataExport?.boolValue == true)
        })
    }
    func coredataServicesNeedingExport() -> [Service] {
        return allCoredataServices.filter({ (service) -> Bool in
            return (service.bqNeedsCoreDataExport?.boolValue == true)
        })
    }
    func coredataAppointmentsNeedingExport() -> [Appointment] {
        return allUnexpiredCoredataAppointments.filter({ (appointment) -> Bool in
            return (appointment.bqNeedsCoreDataExport?.boolValue == true)
        })
    }
    func coredataSalesNeedingExport() -> [Sale] {
        return allCoredataSales.filter({ (sale) -> Bool in
            return (sale.bqNeedsCoreDataExport?.boolValue == true)
        })
    }
    func coredataSaleItemsNeedingExport() -> [SaleItem] {
        return allCoredataSaleItems.filter({ (saleItem) -> Bool in
            return (saleItem.bqNeedsCoreDataExport?.boolValue == true)
        })
    }
    
    // MARK:- Make export records for coredata objects
    func makeExportRecordsForCoredataCustomers() -> [CKRecord] {
        var icloudCustomerRecords = [CKRecord]()
        totalCustomersToProcess = 0
        extractedCustomerCount = 0
        for customerForExport in coredataCustomersNeedingExport() {
            let icloudCustomer = ICloudCustomer(coredataCustomer: customerForExport, parentSalonID: self.salonID)
            let ckRecord = icloudCustomer.makeCloudKitRecord()
            icloudCustomerRecords.append(ckRecord)
            totalCustomersToProcess += 1
        }
        return icloudCustomerRecords
    }
    func makeExportRecordsForCoredataEmployees() -> [CKRecord] {
        var icloudEmployeeRecords = [CKRecord]()
        totalEmployeesToProcess = 0
        extractedEmployeesCount = 0
        for employeeForExport in coredataEmployeesNeedingExport() {
            let icloudEmployee = ICloudEmployee(coredataEmployee: employeeForExport, parentSalonID: self.salonID)
            let ckRecord = icloudEmployee.makeCloudKitRecord()
            icloudEmployeeRecords.append(ckRecord)
            totalEmployeesToProcess += 1
        }
        return icloudEmployeeRecords
    }
    func makeExportRecordsForCoredataServiceCategies() -> [CKRecord] {
        var icloudServiceCategoryRecords = [CKRecord]()
        totalServiceCategoriesToProcess = 0
        extractedServiceCategoriesCount = 0
        for serviceCategoryForExport in coredataServiceCategoriesNeedingExport() {
            let icloudServiceCategory = ICloudServiceCategory(coredataServiceCategory: serviceCategoryForExport, parentSalonID: self.salonID)
            let ckRecord = icloudServiceCategory.makeCloudKitRecord()
            icloudServiceCategoryRecords.append(ckRecord)
            totalServiceCategoriesToProcess += 1
        }
        return icloudServiceCategoryRecords
    }
    func makeExportRecordsForCoredataServices() -> [CKRecord] {
        var icloudServiceRecords = [CKRecord]()
        totalServicesToProcess = 0
        extractedServicesCount = 0
        for serviceForExport in coredataServicesNeedingExport() {
            if let _ = serviceForExport.serviceCategory {
                let icloudService = ICloudService(coredataService: serviceForExport, parentSalonID: self.salonID)
                let ckRecord = icloudService.makeCloudKitRecord()
                icloudServiceRecords.append(ckRecord)
                totalServicesToProcess += 1
            }
        }
        return icloudServiceRecords
    }
    /** Output array will also include records for each appointment's child Sale and SaleItems */
    func makeExportRecordsForCoredataAppointments() -> [CKRecord] {
        var icloudRecords = [CKRecord]()
        totalAppointmentsToProcess = 0
        totalSalesToProcess = 0
        totalSaleItemsToProcess = 0
        extractedAppointmentsCount = 0
        extractedSalesCount = 0
        extractedSaleItemsCount = 0
        for appointmentForExport in coredataAppointmentsNeedingExport() {
            let icloudAppointment = ICloudAppointment(coredataAppointment: appointmentForExport, parentSalonID: self.salonID)
            let ckAppointmentRecord = icloudAppointment.makeCloudKitRecord()
            icloudRecords.append(ckAppointmentRecord)
            totalAppointmentsToProcess += 1
            // Add child Sale record
            if let saleForExport = appointmentForExport.sale {
                let icloudSale = ICloudSale(coredataSale: saleForExport, parentSalonID: self.salonID)
                let ckSaleRecord = icloudSale.makeCloudKitRecord()
                icloudRecords.append(ckSaleRecord)
                totalSalesToProcess += 1
                for saleItemForExport in saleForExport.saleItem! {
                    let icloudSaleItem = ICloudSaleItem(coredataSaleItem: saleItemForExport, parentSalonID: self.salonID)
                    let ckSaleItemRecord = icloudSaleItem.makeCloudKitRecord()
                    icloudRecords.append(ckSaleItemRecord)
                    totalSaleItemsToProcess += 1
                }
            }
        }
        return icloudRecords
    }
    
    // MARK:- prepare coredata objects for export
    func prepareAllCustomersForCoredataExport() {
        allCoredataCustomers = Customer.customersOrderedByFirstName(moc)
        coredataCustomersDictionary.removeAll()
        for customer in allCoredataCustomers {
            let uid = uidStringFromManagedObject(customer)
            coredataCustomersDictionary[uid] = customer
            customer.bqNeedsCoreDataExport = NSNumber(bool: true)
            customer.bqMetadata = nil
        }
    }
    func prepareAllEmployeesForCoredataExport() {
        allCoredataEmployees = Employee.employeesOrderedByFirstName(moc)
        coredataEmployeeDictionary.removeAll()
        for employee in allCoredataEmployees {
            let uid = uidStringFromManagedObject(employee)
            coredataEmployeeDictionary[uid] = employee
            employee.bqNeedsCoreDataExport = NSNumber(bool: true)
            employee.bqMetadata = nil
        }
    }
    func prepareAllServiceCategoriesForCoredataExport() {
        allCoredataServiceCategories = ServiceCategory.serviceCategoriesOrderedByName(moc)
        coredataServiceCategoriesDictionary.removeAll()
        for serviceCategory in allCoredataServiceCategories {
            let uid = uidStringFromManagedObject(serviceCategory)
            coredataServiceCategoriesDictionary[uid] = serviceCategory
            serviceCategory.bqNeedsCoreDataExport = NSNumber(bool: true)
            serviceCategory.bqMetadata = nil
        }
    }
    
    func prepareAllServicesForCoredataExport() {
        allCoredataServices = Service.servicesOrderedByName(moc)
        coredataServicesDictionary.removeAll()
        for service in allCoredataServices {
            let uid = uidStringFromManagedObject(service)
            coredataServicesDictionary[uid] = service
            service.bqNeedsCoreDataExport = NSNumber(bool: true)
            service.bqMetadata = nil
        }
    }
    func prepareAllAppointmentsForCoredataExport() {
        allUnexpiredCoredataAppointments = Appointment.unexpiredAppointments(moc)
        coredataAppointmentsDictionary.removeAll()
        for appointment in allUnexpiredCoredataAppointments {
            let uid = uidStringFromManagedObject(appointment)
            coredataAppointmentsDictionary[uid] = appointment
            prepareAppointmentForCoredataExport(appointment, requiresExport: true)
        }
    }
    func prepareAppointmentForCoredataExport(appointment: Appointment, requiresExport: Bool) {
        appointment.bqNeedsCoreDataExport = NSNumber(bool: requiresExport);
        appointment.bqMetadata = nil
        appointment.sale?.bqNeedsCoreDataExport = NSNumber(bool: requiresExport)
        appointment.sale?.bqMetadata = nil
        for saleItem in appointment.sale!.saleItem! {
            saleItem.bqNeedsCoreDataExport = NSNumber(bool: requiresExport)
            saleItem.bqMetadata = nil
        }
    }
    
    // MARK:- Create operation to extract top-level salon object
    func extractSalonOperation() -> CKModifyRecordsOperation {
        let cloudSalon = ICloudSalon(coredataSalon: self.salon)
        cloudSalonRecord = cloudSalon.makeCloudKitRecord()
        let recordsToSave = [cloudSalonRecord!]
        let operation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
        operation.modifyRecordsCompletionBlock = { (saveRecords:[CKRecord]?,deleteRecordIDs:[CKRecordID]?,error:NSError?) in
            if error != nil {
                print("Oops")
                return
            }
            guard let cloudRecord = saveRecords?[0] else {
                // No record was saved!!
                assertionFailure("No error was reported but the record was absent")
                return
            }
            let metadata = archiveMetadataForCKRecord(cloudRecord)
            self.salonDocument.salon.bqMetadata = metadata
            self.cloudSalonRecord = cloudRecord
            self.cloudSalonReference = CKReference(record: self.cloudSalonRecord!, action: CKReferenceAction.DeleteSelf)
            
        }
        return operation
    }
    
    // MARK:- Save operation and completion logic
    func recordWasSaved(record:CKRecord?, error:NSError?) {
        if error != nil {
            assertionFailure("Unhandled error in perRecordCompletionBlock")
            return
        }
        NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
            if let recordType = record?.recordType {
                let cloudID = record!.recordID.recordName
                let metadata = archiveMetadataForCKRecord(record!)
                switch recordType {
                case ICloudRecordType.Customer.rawValue:
                    let coredataCustomer = self.coredataCustomersDictionary[cloudID]
                    coredataCustomer?.bqNeedsCoreDataExport = NSNumber(bool: false)
                    coredataCustomer?.bqMetadata = metadata
                    self.extractedCustomerCount += 1
                    self.delegate?.coredataRecordWasExtracted(self, recordType: recordType, extractCount: self.extractedCustomerCount, total: self.totalCustomersToProcess)
                    
                case ICloudRecordType.Employee.rawValue:
                    let coredataEmployee = self.coredataEmployeeDictionary[cloudID]
                    coredataEmployee?.bqNeedsCoreDataExport = NSNumber(bool: false)
                    coredataEmployee?.bqMetadata = metadata
                    self.extractedEmployeesCount += 1
                    self.delegate?.coredataRecordWasExtracted(self, recordType: recordType, extractCount: self.extractedEmployeesCount, total: self.totalEmployeesToProcess)
                    
                case ICloudRecordType.ServiceCategory.rawValue:
                    let coredataServiceCategory = self.coredataServiceCategoriesDictionary[cloudID]
                    coredataServiceCategory?.bqNeedsCoreDataExport = NSNumber(bool: false)
                    coredataServiceCategory?.bqMetadata = metadata
                    self.extractedServiceCategoriesCount += 1
                    self.delegate?.coredataRecordWasExtracted(self, recordType: recordType, extractCount: self.extractedServiceCategoriesCount, total: self.totalServiceCategoriesToProcess)
                    if self.extractedServiceCategoriesCount == self.totalServiceCategoriesToProcess {
                        // services are dependent on the serviceCategories operation because serviceCategories own services
                        let serviceRecords = self.makeExportRecordsForCoredataServices()
                        let servicesOperation = self.saveRecordsOperation(serviceRecords)
                        self.publicDatabase.addOperation(servicesOperation)
                    }
                    
                case ICloudRecordType.Service.rawValue:
                    let coredataService = self.coredataServicesDictionary[cloudID]
                    coredataService?.bqNeedsCoreDataExport = NSNumber(bool: false)
                    coredataService?.bqMetadata = metadata
                    self.extractedServicesCount += 1
                    self.delegate?.coredataRecordWasExtracted(self, recordType: recordType, extractCount: self.extractedServicesCount, total: self.totalServicesToProcess)
                    if self.extractedServicesCount == self.totalServicesToProcess {
                        let appointmentRecords = self.makeExportRecordsForCoredataAppointments()
                        let appointmentOperation = self.saveRecordsOperation(appointmentRecords)
                        self.publicDatabase.addOperation(appointmentOperation)
                    }

                case ICloudRecordType.Appointment.rawValue:
                    let coredataAppointment = self.coredataAppointmentsDictionary[cloudID]
                    coredataAppointment?.bqNeedsCoreDataExport = NSNumber(bool: false)
                    coredataAppointment?.bqMetadata = metadata
                    self.extractedAppointmentsCount += 1
                    self.delegate?.coredataRecordWasExtracted(self, recordType: recordType, extractCount: self.extractedAppointmentsCount, total: self.totalAppointmentsToProcess)
                default: break
                }
            }
        })
    }
    func retryOperation(operation:CKModifyRecordsOperation, waitInterval:Double) {
        let waitIntervalNanoseconds = Int64(waitInterval * 1000_000_000.0)
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, waitIntervalNanoseconds)
        dispatch_after(dispatchTime, dispatch_get_main_queue()) { () -> Void in
            self.publicDatabase.addOperation(operation)
        }
    }
    func saveRecordsOperation(customerRecords:[CKRecord]) -> CKModifyRecordsOperation {
        // Create the operation that we will return
        let saveOperation = CKModifyRecordsOperation(recordsToSave: customerRecords, recordIDsToDelete: nil)
        saveOperation.savePolicy = CKRecordSavePolicy.ChangedKeys
        
        // Record completes
        saveOperation.perRecordCompletionBlock = { (record:CKRecord?, error:NSError?) in self.recordWasSaved(record, error: error) }
        
        // All records complete
        saveOperation.modifyRecordsCompletionBlock = { (saveRecords:[CKRecord]?,deleteRecordIDs:[CKRecordID]?,error:NSError?) in
            guard let recordsToSave = saveOperation.recordsToSave else {
                return
            }
            if let error = error {
                switch error.code {
                case CKErrorCode.LimitExceeded.rawValue:
                    // Too many records - need to recurse down to smaller operations
                    let n = recordsToSave.count / 2
                    var recordsA = [CKRecord]()
                    var recordsB = [CKRecord]()
                    for index in recordsToSave.indices {
                        if index <= n {
                            recordsA.append(recordsToSave[index])
                        } else {
                            recordsB.append(recordsToSave[index])
                        }
                    }
                    // Recurse with the smaller operations
                    let operationA = self.saveRecordsOperation(recordsA)
                    let operationB = self.saveRecordsOperation(recordsB)
                    self.publicDatabase.addOperation(operationA)
                    self.publicDatabase.addOperation(operationB)
                case CKErrorCode.PartialFailure.rawValue:
                    // TODO: Work out why this happens. One possibility is that a record has a reference to a parent object that has not yet been saved
                    assertionFailure("We need to work out how to handle this")
                    break
                case CKErrorCode.ZoneBusy.rawValue,
                     CKErrorCode.RequestRateLimited.rawValue,
                     CKErrorCode.ServiceUnavailable.rawValue:
                    // All these errors are transient and the operation can be retried after a suitable wait
                    guard let retryAfter = error.userInfo["CKErrorRetryAfterKey"]?.doubleValue else {
                        preconditionFailure("Expected a retry interval but none found in error's userinfo")
                    }
                    self.retryOperation(saveOperation, waitInterval: retryAfter)
                    break
                case CKErrorCode.NetworkFailure.rawValue:
                    break
                case CKErrorCode.NetworkUnavailable.rawValue:
                    // TODO: call a retry mechanism?
                    break
                default:
                    assertionFailure("Unhandled error")
                }
                return
            }
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if self.totalCustomersToProcess == self.extractedCustomerCount {
                    // Notify customer extract is complete
                }
                self.salonDocument.saveDocument(self)
                if self.isFullExtractComplete() {
                    self.delegate?.fullCoredataExtractWasCompleted(self)
                }
            })
        }
        return saveOperation
    }
    
    func isFullExtractComplete()->Bool {
        if self.totalCustomersToProcess > self.extractedCustomerCount { return false }
        if self.totalServiceCategoriesToProcess > self.extractedServiceCategoriesCount { return false }
        if self.totalServicesToProcess > self.extractedServicesCount { return false }
        if self.totalEmployeesToProcess > self.extractedEmployeesCount { return false }
        if self.totalAppointmentsToProcess > self.extractedAppointmentsCount { return false }
        return true
    }
}


extension BQFirstExtractController {
    func removeAllCloudReferences() {
        let bqExportableArraysArray = self.bqExportableArrays()
        for bqExportableObjects in bqExportableArraysArray {
            for exportable in bqExportableObjects {
                self.removeAllCloudReferencesFromBQExportable(exportable)
            }
        }
        do {
            try self.moc.save()
        } catch {
            print("Unable to save moc \(error)")
        }
    }
    private func bqExportableArrays() -> [[BQExportable]] {
        var array = [[BQExportable]]()
        array.append([Salon.defaultSalon(moc)!])
        array.append(Customer.customersOrderedByFirstName(moc))
        array.append(Employee.employeesOrderedByFirstName(moc))
        array.append(ServiceCategory.serviceCategoriesOrderedByName(moc))
        array.append(Service.servicesOrderedByName(moc))
        array.append(Appointment.allObjectsWithMoc(moc) as! [BQExportable])
        array.append(Sale.allObjectsWithMoc(moc) as! [BQExportable])
        array.append(SaleItem.allObjectsWithMoc(moc) as! [BQExportable])
        return array
    }
    private func removeAllCloudReferencesFromBQExportable(bqExportable:BQExportable) {
        bqExportable.bqCloudID = ""
        bqExportable.bqMetadata = nil
        bqExportable.bqHasClientChanges = false
        bqExportable.bqNeedsCloudImport = false
        bqExportable.bqNeedsCoreDataExport = false
    }
}
