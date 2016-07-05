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
    private let cloudRecordTypesToCheckForCompletion = [ICloudRecordType.CRCustomer,
                                                ICloudRecordType.CRServiceCategory,
                                                ICloudRecordType.CRServiceCategory,
                                                ICloudRecordType.CREmployee,
                                                ICloudRecordType.CRAppointment]

    var delegate: BQFirstExtractControllerDelegate?
    private (set) var salonDocument: AMCSalonDocument!
    private (set) var salon: Salon!
    private (set) var salonManagedObjectID: NSManagedObjectID!
    let icloudContainer = CKContainer.defaultContainer()
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    private let synchronisationQueue = dispatch_queue_create("com.AMCAldebaron.BQCoredataExportController", DISPATCH_QUEUE_SERIAL)
    
    var totalRecordsToProcess = [ICloudRecordType:Int]()
    var extractedRecordsCount = [ICloudRecordType:Int]()
    var allCoredataRecords = [ICloudRecordType:[BQExportable]]()
    
    // Dictionary of dictionaries. The inner dictionary's key is a UUID which uniquely defines the BQExportable object in the cloud
    typealias CloudRecordName = String
    typealias CoredataDictionary = Dictionary<NSManagedObjectID,BQExportable>
    var coredataRecordsDictionaryOfDictionaries = [ICloudRecordType:CoredataDictionary]()
    var cloudToCoredataMapping = [CloudRecordName:NSManagedObjectID]()
    
    var cloudSalonRecord: CKRecord?
    var cloudSalonReference: CKReference?
    let parentManagedObjectContext:NSManagedObjectContext
    var moc: NSManagedObjectContext!
    
    init(salonDocument:AMCSalonDocument) {
        self.salonDocument = salonDocument
        self.parentManagedObjectContext = salonDocument.managedObjectContext!
        self.salonManagedObjectID = salonDocument.salon.objectID
        self.moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.moc.parentContext = self.parentManagedObjectContext
        self.moc.performBlockAndWait() {
            self.salon = self.moc.objectWithID(self.salonManagedObjectID) as! Salon
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
            self.allCoredataRecords.removeAll()
            self.coredataRecordsDictionaryOfDictionaries.removeAll()
            self.cloudToCoredataMapping.removeAll()
            
            self.prepareBQExportablesForExport(ICloudRecordType.CRSalon)
            self.prepareBQExportablesForExport(ICloudRecordType.CRCustomer)
            self.prepareBQExportablesForExport(ICloudRecordType.CREmployee)
            self.prepareBQExportablesForExport(ICloudRecordType.CRServiceCategory)
            self.prepareBQExportablesForExport(ICloudRecordType.CRService)
            self.prepareBQExportablesForExport(ICloudRecordType.CRAppointment)
            self.prepareBQExportablesForExport(ICloudRecordType.CRAccount)
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
}

extension BQFirstExtractController {

    // MARK:- create arrays of coredata objects requiring export to icloud
    func coredataRecordsNeedingExport(cloudRecordType:ICloudRecordType) -> [BQExportable] {
        return allCoredataRecords[cloudRecordType]!.filter { (bqExportable) -> Bool in
            return (bqExportable.bqNeedsCoreDataExport?.boolValue == true)
        }
    }
}

extension BQFirstExtractController {

    // MARK:- Make export records for coredata objects
    func makeExportRecordsForCloudRecordType(cloudRecordType:ICloudRecordType) -> [CKRecord] {
        var icloudRecords = [CKRecord]()
        totalRecordsToProcess[cloudRecordType] = 0
        extractedRecordsCount[cloudRecordType] = 0
        var total = 0
        for bqExportable in coredataRecordsNeedingExport(cloudRecordType) {
            let icloudObject = ICloudRecord.makeICloudRecord(bqExportable, parentSalonID: self.salonManagedObjectID)
            let ckRecord = icloudObject.makeCloudKitRecord()
            icloudRecords.append(ckRecord)
            total += 1
            totalRecordsToProcess[cloudRecordType] = total
            self.cloudToCoredataMapping[ckRecord.recordID.recordName] = bqExportable.objectID
            bqExportable.objectID
        }
        return icloudRecords
    }
    
    /** Output array will also include records for each appointment's child Sale and SaleItems */
    func incrementTotalToProcess(icloudRecordType:ICloudRecordType) {
        totalRecordsToProcess[icloudRecordType] = totalRecordsToProcess[icloudRecordType]! + 1
    }
    
    func makeExportRecordsForCoredataAppointments() -> [CKRecord] {
        var icloudRecords = [CKRecord]()
        for appointmentForExport in coredataRecordsNeedingExport(ICloudRecordType.CRAppointment) as! [Appointment] {
            let icloudAppointment = ICloudAppointment(coredataAppointment: appointmentForExport, parentSalonID: self.salonManagedObjectID)
            let ckAppointmentRecord = icloudAppointment.makeCloudKitRecord()
            icloudRecords.append(ckAppointmentRecord)
            self.incrementTotalToProcess(.CRAppointment)
            // Add child Sale record
            if let saleForExport = appointmentForExport.sale {
                let icloudSale = ICloudSale(coredataSale: saleForExport, parentSalonID: self.salonManagedObjectID)
                let ckSaleRecord = icloudSale.makeCloudKitRecord()
                icloudRecords.append(ckSaleRecord)
                self.incrementTotalToProcess(ICloudRecordType.CRSale)
                for saleItemForExport in saleForExport.saleItem! {
                    let icloudSaleItem = ICloudSaleItem(coredataSaleItem: saleItemForExport, parentSalonID: self.salonManagedObjectID)
                    let ckSaleItemRecord = icloudSaleItem.makeCloudKitRecord()
                    icloudRecords.append(ckSaleItemRecord)
                    self.incrementTotalToProcess(ICloudRecordType.CRSaleItem)
                }
            }
        }
        return icloudRecords
    }
}

extension BQFirstExtractController {

    // MARK:- prepare coredata objects for export
    func prepareBQExportablesForExport(icloudRecordType:ICloudRecordType) {
        allCoredataRecords[icloudRecordType] = icloudRecordType.fetchAllBQExportables(moc)
        self.prepareStandardBQExportables(allCoredataRecords[icloudRecordType]!)
        switch icloudRecordType {
            
            // Types requiring only base-class type processing here...
        case ICloudRecordType.CRSalon: break
        case ICloudRecordType.CRCustomer: break
        case ICloudRecordType.CREmployee: break
        case ICloudRecordType.CRServiceCategory: break
        case ICloudRecordType.CRService: break
        case ICloudRecordType.CRPaymentCategory: break

    
            // Types requiring non-standard processing here
        case ICloudRecordType.CRAppointment:
            self.additionalCoredataExportPreparation(allCoredataRecords[icloudRecordType] as! [Appointment])
        case ICloudRecordType.CRAccount:
            self.additionalCoredataExportPreparation(allCoredataRecords[icloudRecordType] as! [Account])
            
            // Types that are exported as nested sub-objects don't need any preparation
        case ICloudRecordType.CRSale,
             ICloudRecordType.CRSaleItem,
             ICloudRecordType.CRAccountReconciliation,
             ICloudRecordType.CRPayment:
            fatalError("Non standard export required")
        }
    }
        
    private func prepareStandardBQExportables(standardExportables:[BQExportable]) {
        for bqExportable in standardExportables {
            let icloudRecordType = ICloudRecordType(bqExportable: bqExportable)
            coredataRecordsDictionaryOfDictionaries[icloudRecordType]![bqExportable.objectID] = bqExportable
            bqExportable.prepareForInitialExport()
        }
    }
    
    private func additionalCoredataExportPreparation(appointments:[Appointment]) {
        for appointment in appointments {
            appointment.sale?.prepareForInitialExport()
            for saleItem in appointment.sale!.saleItem! {
                saleItem.prepareForInitialExport()
            }
        }
    }

    func additionalCoredataExportPreparation(accounts: [Account]) {
        for account in allCoredataRecords[ICloudRecordType.CRAccount]! as! [Account] {
            account.bqNeedsCoreDataExport = true
            account.bqMetadata = nil
        }
    }
}

extension BQFirstExtractController {

    // MARK:- Create operation to extract top-level salon object
    func extractSalonOperation() -> CKModifyRecordsOperation {
        let cloudSalon = ICloudSalon(coredataSalon: self.salon)
        
        cloudSalonRecord = cloudSalon.makeCloudKitRecord()
        let recordsToSave = self.makeExportRecordsForCloudRecordType(ICloudRecordType.CRSalon)
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
                
                let customerRecords = self.makeExportRecordsForCloudRecordType(ICloudRecordType.CRCustomer)
                let employeeRecords = self.makeExportRecordsForCloudRecordType(ICloudRecordType.CREmployee)
                let serviceCategoryRecords = self.makeExportRecordsForCloudRecordType(ICloudRecordType.CRServiceCategory)
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
    func incrementExtractedRecordCount(icloudRecordType:ICloudRecordType) {
        extractedRecordsCount[icloudRecordType] = extractedRecordsCount[icloudRecordType]! + 1
    }
    func recordWasSaved(record:CKRecord?, error:NSError?) {
        if error != nil {
            assertionFailure("Unhandled error in perRecordCompletionBlock")
            return
        }
        self.moc.performBlockAndWait {
            
            guard let recordType = record?.recordType else {
                assertionFailure("Error in recordWasSaved: \(error)")
                return
            }
            
            let cloudID = record!.recordID.recordName
            let metadata = archiveMetadataForCKRecord(record!)
            let icloudRecordType = ICloudRecordType(rawValue: recordType)!
            let coredataDictionary = self.coredataRecordsDictionaryOfDictionaries[icloudRecordType]!
            let bqExportable = coredataDictionary[self.managedObjectIDForCloudRecordName(cloudID)!]!
            bqExportable.bqNeedsCoreDataExport = false
            bqExportable.bqMetadata = metadata
            self.incrementExtractedRecordCount(icloudRecordType)
            let total = self.totalRecordsToProcess[icloudRecordType]!
            let extracted = self.extractedRecordsCount[icloudRecordType]!
            self.delegate?.coredataRecordWasExtracted(self, recordType: recordType, extractCount: extracted, total: total)

            switch icloudRecordType {
            case ICloudRecordType.CRServiceCategory:
                if self.extractedRecordsCount[ICloudRecordType.CRServiceCategory] == self.totalRecordsToProcess[ICloudRecordType.CRServiceCategory] {
                    // services are dependent on the serviceCategories operation because serviceCategories own services
                    let serviceRecords = self.makeExportRecordsForCloudRecordType(ICloudRecordType.CRService)
                    let servicesOperation = self.saveRecordsOperation(serviceRecords)
                    self.publicDatabase.addOperation(servicesOperation)
                }
                
            case ICloudRecordType.CRService:
                if self.extractedRecordsCount[ICloudRecordType.CRService] == self.totalRecordsToProcess[ICloudRecordType.CRService] {
                    let appointmentRecords = self.makeExportRecordsForCoredataAppointments()
                    let appointmentOperation = self.saveRecordsOperation(appointmentRecords)
                    self.publicDatabase.addOperation(appointmentOperation)
                }
                
            case ICloudRecordType.CRAccountReconciliation:
                break
                
            case ICloudRecordType.CRPaymentCategory:
                break
                
            case ICloudRecordType.CRPayment:
                break
                
            case ICloudRecordType.CRCustomer: break
            case ICloudRecordType.CREmployee: break
            case ICloudRecordType.CRAppointment: break
            case ICloudRecordType.CRSale: break
            case ICloudRecordType.CRSaleItem: break
            case ICloudRecordType.CRSalon: break
            case ICloudRecordType.CRAccount:break
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
        for icloudRecordType in self.cloudRecordTypesToCheckForCompletion {
            if self.totalRecordsToProcess[icloudRecordType] > self.extractedRecordsCount[icloudRecordType] {
                return false
            }
        }
        return true
    }
}


extension BQFirstExtractController {
    func managedObjectIDForCloudRecordName(cloudRecordName:CloudRecordName) -> NSManagedObjectID? {
        return self.cloudToCoredataMapping[cloudRecordName]
    }
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
        // Belt and braces - this should already have been done but we've had problems with this before
        self.moc.performBlockAndWait {
            for (_,exportableDictionary) in self.coredataRecordsDictionaryOfDictionaries {
                for (_,bqExportable) in exportableDictionary {
                    bqExportable.bqNeedsCoreDataExport = false
                    bqExportable.bqHasClientChanges = false
                }
            }
        }
    }
}
