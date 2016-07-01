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
    var extractedAccountsCount = 0
    
    var totalRecordsToProcess = [ICloudRecordType:Int]()
    var extractedRecordsCount = [ICloudRecordType:Int]()
    var allCoredataRecords = [ICloudRecordType:[BQExportable]]()
    
    // Dictionary of dictionaries. The inner dictionary's key is a UUID which uniquely defines the BQExportable object in the cloud
    var coredataRecordsDictionaryOfDictionaries = [ICloudRecordType:[String:BQExportable]]()
    
    var totalCustomersToProcess = 0
    var totalEmployeesToProcess = 0
    var totalServiceCategoriesToProcess = 0
    var totalServicesToProcess = 0
    var totalAppointmentsToProcess = 0
    var totalSalesToProcess = 0
    var totalSaleItemsToProcess = 0
    var totalAccountsToProcess = 0
    
    var allCoredataCustomers = [Customer]()
    var allCoredataEmployees = [Employee]()
    var allCoredataServiceCategories = [ServiceCategory]()
    var allCoredataServices = [Service]()
    var allUnexpiredCoredataAppointments = [Appointment]()
    var allCoredataSales = [Sale]()
    var allCoredataSaleItems = [SaleItem]()
    var allCoredataAccounts = [Account]()
    
    var coredataCustomersDictionary = [String:Customer]()
    var coredataEmployeeDictionary = [String:Employee]()
    var coredataServiceCategoriesDictionary = [String:ServiceCategory]()
    var coredataServicesDictionary = [String:Service]()
    var coredataAppointmentsDictionary = [String:Appointment]()
    var coredataAccountsDictionary = [String:Account]()
    
    var cloudSalonRecord: CKRecord?
    var cloudSalonReference: CKReference?
    let parentManagedObjectContext:NSManagedObjectContext
    var moc: NSManagedObjectContext!
    
    init(salonDocument:AMCSalonDocument) {
        self.salonDocument = salonDocument
        self.parentManagedObjectContext = salonDocument.managedObjectContext!
        self.salonID = salonDocument.salon.objectID
        self.moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.moc.parentContext = self.parentManagedObjectContext
        self.moc.performBlockAndWait() {
            self.salon = self.moc.objectWithID(self.salonID) as! Salon
        }
        // Ensure that all coredata changes are committed
        self.saveToDocument()
    }
    
    // MARK: Prepare coredata for clean extract
    func resetDataExtract() {
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
        self.moc.performBlockAndWait() {
            self.salon.bqNeedsCoreDataExport = true
            self.salon.bqMetadata = nil;
            self.prepareAllCustomersForCoredataExport()
            self.prepareAllEmployeesForCoredataExport()
            self.prepareAllServiceCategoriesForCoredataExport()
            self.prepareAllServicesForCoredataExport()
            self.prepareAllAppointmentsForCoredataExport()
            self.prepareAllAccountsForCoredataExport()
        }
        self.saveToDocument()
    }
    
    private func saveToDocument() {
        self.moc.performBlockAndWait() {
            guard self.moc.hasChanges  else {return}
            do {
                try self.moc.save()
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.salonDocument.saveDocument(self)
                }
            } catch {
                print("Unable to save to document: \(error)")
            }
        }
    }
    
    // MARK:- Extract data
    func extractData() {
        if moc == nil { preconditionFailure("No managed object context") }
        self.prepareCoredataRecordsReadyForFirstExport()

        // Create operation to extract the coredata salon
        let salonOperation = extractSalonOperation()

        // Everything is dependent on the salon operation
        self.publicDatabase.addOperation(salonOperation)
    }
    
    // MARK:- create arrays of coredata objects requiring export to icloud
    func coredataRecordsNeedingExport(cloudRecordType:ICloudRecordType) -> [BQExportable] {
        return allCoredataRecords[cloudRecordType].filter { (bqExportable) -> Bool in
            return (bqExportable.bqNeedsCoreDataExport?.boolValue == true)
        }
    }
    
    
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
    func coredataAccountsNeedingExport() -> [Account] {
        return allCoredataAccounts.filter({ (account) -> Bool in
            return (account.bqNeedsCoreDataExport?.boolValue == true)
        })
    }
    
    // MARK:- Make export records for coredata objects
    func makeExportRecordsForCloudRecordType(cloudRecordType:ICloudRecordType) -> [CKRecord] {
        var icloudRecords = [CKRecord]()
        totalRecordsToProcess[cloudRecordType] = 0
        extractedRecordsCount[cloudRecordType] = 0
    }
    
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
    
    func makeExportRecordsForCoredataAccounts() -> [CKRecord] {
        var iclouAccountRecords = [CKRecord]()
        totalAccountsToProcess = 0
        extractedAccountsCount = 0
        for account in
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
    func prepareBQExportablesForExport(icloudRecordType:ICloudRecordType) {
        coredataRecordsDictionaryOfDictionaries[icloudRecordType]!.removeAll()
        
        switch icloudRecordType {
        case ICloudRecordType.CRCustomer:
            allCoredataRecords[icloudRecordType] = Customer.customersOrderedByFirstName(moc)
            self.prepareStandardBQExportables(allCoredataRecords[icloudRecordType]!)
        case ICloudRecordType.CREmployee:
            allCoredataRecords[icloudRecordType] = Employee.employeesOrderedByFirstName(moc)
            self.prepareStandardBQExportables(allCoredataRecords[icloudRecordType]!)
        case ICloudRecordType.CRServiceCategory:
            allCoredataRecords[icloudRecordType] = ServiceCategory.serviceCategoriesOrderedByName(moc)
            self.prepareStandardBQExportables(allCoredataRecords[icloudRecordType]!)
        case ICloudRecordType.CRService:
            allCoredataRecords[icloudRecordType] = Service.servicesOrderedByName(moc)
            self.prepareStandardBQExportables(allCoredataRecords[icloudRecordType]!)
    

        case ICloudRecordType.CRSalon:
            fatalError("Non standard")
        case ICloudRecordType.CRAccount:
            fatalError("Non standard")
        case ICloudRecordType.CRAppointment:
            fatalError("Non standard")
        case ICloudRecordType.CRSale:
            fatalError("Non standard")
        case ICloudRecordType.CRSaleItem:
            fatalError("Non standard")
        }
    }
    func prepareStandardBQExportables(standardExportables:[BQExportable]) {
        for bqExportable in standardExportables {
            let icloudRecordType = ICloudRecordType(bqExportable: bqExportable)
            let uid = uidStringFromManagedObject(bqExportable as! NSManagedObject)
            coredataRecordsDictionaryOfDictionaries[icloudRecordType]![uid] = bqExportable
            bqExportable.bqNeedsCoreDataExport = NSNumber(bool: true)
            bqExportable.bqMetadata = nil
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
    func prepareAllAccountsForCoredataExport() {
        allCoredataAccounts = Account.allObjectsWithMoc(moc) as! Array<Account>
        coredataAccountsDictionary.removeAll()
        for account in allCoredataAccounts {
            self.prepareAccountForCoredataExport(account, requiresExport: true)
        }
    }
    func prepareAccountForCoredataExport(account:Account, requiresExport:Bool) {
        account.bqNeedsCoreDataExport = requiresExport
        account.bqMetadata = nil
    }
    
    // MARK:- Create operation to extract top-level salon object
    func extractSalonOperation() -> CKModifyRecordsOperation {
        let cloudSalon = ICloudSalon(coredataSalon: self.salon)
        cloudSalonRecord = cloudSalon.makeCloudKitRecord()
        let recordsToSave = [cloudSalonRecord!]
        let salonOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: nil)
        salonOperation.modifyRecordsCompletionBlock = { (saveRecords:[CKRecord]?,deleteRecordIDs:[CKRecordID]?,error:NSError?) in
            if error != nil {
                print("Oops")
                return
            }
            guard let cloudRecord = saveRecords?[0] else {
                // No record was saved!!
                assertionFailure("No error was reported but the record was absent")
                return
            }
            
            self.moc.performBlockAndWait() {

                let metadata = archiveMetadataForCKRecord(cloudRecord)
                self.salon.bqMetadata = metadata
                self.salon.bqNeedsCoreDataExport = false
                self.cloudSalonRecord = cloudRecord
                self.cloudSalonReference = CKReference(record: self.cloudSalonRecord!, action: CKReferenceAction.DeleteSelf)
                
                // Make export records for each entity and then create operations to export them
                
                let customerRecords = self.makeExportRecordsForCoredataCustomers()
                let employeeRecords = self.makeExportRecordsForCoredataEmployees()
                let serviceCategoryRecords = self.makeExportRecordsForCoredataServiceCategies()
                // Don't make export records for services here - they are dealt with in serviceCategory completion
                
                // Create operations to do the export
                let customersOperation = self.saveRecordsOperation(customerRecords)
                let employeesOperation = self.saveRecordsOperation(employeeRecords)
                let serviceCategoriesOperation = self.saveRecordsOperation(serviceCategoryRecords)
                // Don't create save records operation for services here - they are dealt with in serviceCategory completion
                
                // Make child record operations dependent on the salon operation
                customersOperation.addDependency(salonOperation)
                employeesOperation.addDependency(salonOperation)
                serviceCategoriesOperation.addDependency(salonOperation)
                
                // Execute the operations
                self.publicDatabase.addOperation(customersOperation)
                self.publicDatabase.addOperation(employeesOperation)
                self.publicDatabase.addOperation(serviceCategoriesOperation)
            }
            
        }
        return salonOperation
    }
    
    // MARK:- Save operation and completion logic
    func recordWasSaved(record:CKRecord?, error:NSError?) {
        if error != nil {
            assertionFailure("Unhandled error in perRecordCompletionBlock")
            return
        }
        self.moc.performBlockAndWait {
            
            guard let recordType = record?.recordType else { return }
            
            let cloudID = record!.recordID.recordName
            let metadata = archiveMetadataForCKRecord(record!)
            switch recordType {
            case ICloudRecordType.CRCustomer.rawValue:
                let coredataCustomer = self.coredataCustomersDictionary[cloudID]
                coredataCustomer?.bqNeedsCoreDataExport = NSNumber(bool: false)
                coredataCustomer?.bqMetadata = metadata
                self.extractedCustomerCount += 1
                self.delegate?.coredataRecordWasExtracted(self, recordType: recordType, extractCount: self.extractedCustomerCount, total: self.totalCustomersToProcess)
                
            case ICloudRecordType.CREmployee.rawValue:
                let coredataEmployee = self.coredataEmployeeDictionary[cloudID]
                coredataEmployee?.bqNeedsCoreDataExport = NSNumber(bool: false)
                coredataEmployee?.bqMetadata = metadata
                self.extractedEmployeesCount += 1
                self.delegate?.coredataRecordWasExtracted(self, recordType: recordType, extractCount: self.extractedEmployeesCount, total: self.totalEmployeesToProcess)
                
            case ICloudRecordType.CRServiceCategory.rawValue:
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
                
            case ICloudRecordType.CRService.rawValue:
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
                
            case ICloudRecordType.CRAppointment.rawValue:
                let coredataAppointment = self.coredataAppointmentsDictionary[cloudID]
                coredataAppointment?.bqNeedsCoreDataExport = NSNumber(bool: false)
                coredataAppointment?.bqMetadata = metadata
                self.extractedAppointmentsCount += 1
                self.delegate?.coredataRecordWasExtracted(self, recordType: recordType, extractCount: self.extractedAppointmentsCount, total: self.totalAppointmentsToProcess)
            default: break
            }
        }
    }
    func retryOperation(operation:CKModifyRecordsOperation, waitInterval:Double) {
        waitAndDispatchOnMainQueue(waitInterval) {
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
                    let (recordsA,recordsB) = recordsToSave.subdivideAtIndex(n)
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
            self.saveToDocument()
            let fullyExtracted = self.isFullExtractComplete()
            if fullyExtracted {
                self.markAllRecordsAsExported()
                self.saveToDocument()
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    self.delegate?.fullCoredataExtractWasCompleted(self)
                }
            }
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
        self.moc.performBlockAndWait {
            let bqExportableArraysArray = self.bqExportableArrays()
            for bqExportableObjects in bqExportableArraysArray {
                for exportable in bqExportableObjects {
                    self.removeAllCloudReferencesFromBQExportable(exportable)
                }
            }
        }
        self.saveToDocument()
    }
    private func bqExportableArrays() -> [[BQExportable]] {
        var array = [[BQExportable]]()
        array.append([Salon.defaultSalon(self.moc)!])
        array.append(Customer.customersOrderedByFirstName(self.moc))
        array.append(Employee.employeesOrderedByFirstName(self.moc))
        array.append(ServiceCategory.serviceCategoriesOrderedByName(self.moc))
        array.append(Service.servicesOrderedByName(self.moc))
        array.append(Appointment.allObjectsWithMoc(self.moc) as! [BQExportable])
        array.append(Sale.allObjectsWithMoc(self.moc) as! [BQExportable])
        array.append(SaleItem.allObjectsWithMoc(self.moc) as! [BQExportable])
        return array
    }
    private func removeAllCloudReferencesFromBQExportable(bqExportable:BQExportable) {
        bqExportable.bqCloudID = ""
        bqExportable.bqMetadata = nil
        bqExportable.bqHasClientChanges = false
        bqExportable.bqNeedsCoreDataExport = false
    }
    private func markAllRecordsAsExported() {
        self.moc.performBlockAndWait {
            for array in self .bqExportableArrays() {
                for exportable in array {
                    exportable.bqNeedsCoreDataExport = false
                    exportable.bqHasClientChanges = false
                }
            }
        }
    }
}
