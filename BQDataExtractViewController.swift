//
//  BQDataExtractViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Cocoa
import CloudKit


class BQDataExtractViewController: NSViewController {
    var salonDocument: AMCSalonDocument!
    let icloudContainer = CKContainer.defaultContainer()
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    
    var extractedCustomerCount = 0
    var extractedEmployeesCount = 0
    var extractedServiceCategoriesCount = 0
    var extractedServicesCount = 0

    var totalCustomersToProcess = 0
    var totalEmployeesToProcess = 0
    var totalServiceCategoriesToProcess = 0
    var totalServicesToProcess = 0
    
    var allCoredataCustomers = [Customer]()
    var allCoredataEmployees = [Employee]()
    var allCoredataServiceCategories = [ServiceCategory]()
    var allCoredataServices = [Service]()

    var coredataCustomersDictionary = [String:Customer]()
    var coredataEmployeeDictionary = [String:Employee]()
    var coredataServiceCategoriesDictionary = [String:ServiceCategory]()
    var coredataServicesDictionary = [String:Service]()

    var cloudSalonRecord: CKRecord?
    var cloudSalonReference: CKReference?
    var moc: NSManagedObjectContext! {
        return self.salonDocument.managedObjectContext
    }
    
    @IBOutlet weak var customerProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var employeeProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var serviceCategoryProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var serviceProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!
    @IBOutlet weak var extractStatus: NSTextField!
    

    // MARK:- UI functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.activityIndicator.hidden = true
        self.extractStatus.stringValue = ""
    }
    
    @IBAction func resetDataExtract(sender: AnyObject) {
        // Delete Salon (this should cascade deletes all the way down)
        self.activityIndicator.startAnimation(self)
        deleteAllIcloudData()
        setCoredataRecordsReadyForFirstExport()
    }
    @IBAction func performExtractButtonClicked(sender: AnyObject) {
        extractData()
    }
    
    // Prepare UI for extract
    func zeroUIProgressbars() {
        extractedCustomerCount = 0
        customerProgressIndicator.minValue = 0
        customerProgressIndicator.maxValue = 100
        customerProgressIndicator.doubleValue = 0
        
        employeeProgressIndicator.minValue = 0
        employeeProgressIndicator.maxValue = 100
        employeeProgressIndicator.doubleValue = 0
        
        serviceCategoryProgressIndicator.minValue = 0
        serviceCategoryProgressIndicator.maxValue = 100
        serviceCategoryProgressIndicator.doubleValue = 0

        serviceProgressIndicator.minValue = 0
        serviceProgressIndicator.maxValue = 100
        serviceProgressIndicator.doubleValue = 0
        
        self.activityIndicator.hidden = false
    }

    // Prepare coredata records for extract
    func setCoredataRecordsReadyForFirstExport() {
        self.activityIndicator.startAnimation(self)
        self.salonDocument.salon.bqNeedsCoreDataExport = true
        self.salonDocument.salon.bqMetadata = nil;
        for customer in allCoredataCustomers {
            customer.bqNeedsCoreDataExport = NSNumber(bool: true)
            customer.bqMetadata = nil
        }
        for employee in allCoredataEmployees {
            employee.bqNeedsCoreDataExport = NSNumber(bool: true)
            employee.bqMetadata = nil
        }
        for serviceCategory in allCoredataServiceCategories {
            serviceCategory.bqNeedsCoreDataExport = NSNumber(bool: true)
            serviceCategory.bqMetadata = nil
        }
        for service in allCoredataServices {
            service.bqNeedsCoreDataExport = NSNumber(bool: true)
            service.bqMetadata = nil
        }
        self.activityIndicator.stopAnimation(self)
    }
    
    // Delete all existing extracted records from icloud
    func deleteAllIcloudData() {
        guard let _ = self.salonDocument.salon.bqMetadata else {
            print("deleteAllIcloudData - No salon data to delete!")
            return
        }
        self.activityIndicator.startAnimation(self)
        let icloudSalon = ICloudSalon(managedObject: self.salonDocument.salon)
        publicDatabase.deleteRecordWithID(icloudSalon.recordID!, completionHandler: { (record, error) -> Void in
            if error != nil {
                // Failed to delete the salon?
                assertionFailure("Failed to delete the parent salon")
            } else {
                // Delete worked - check to make sure all child records also deleted
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.activityIndicator.stopAnimation(self)
            })
        })
    }

    // MARK:- Extract data
    func extractData() {
        if moc == nil { preconditionFailure("No managed object context") }
        zeroUIProgressbars()
        activityIndicator.startAnimation(self)
        
        // Create operation to extract the coredata salon
        let salonOperation = extractSalonOperation()
        salonOperation.completionBlock = { () -> Void in
            // Prepare the salon's child data for export
            self.prepareAllCustomersForCoredataExport()
            self.prepareAllEmployeesForCoredataExport()
            self.prepareAllServiceCategoriesForCoredataExport()
            self.prepareAllServicesForCoredataExport()
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
    
    // MARK:- Make export records for coredata objects
    func makeExportRecordsForCoredataCustomers() -> [CKRecord] {
        var icloudCustomerRecords = [CKRecord]()
        for customerForExport in coredataCustomersNeedingExport() {
            let icloudCustomer = ICloudCustomer(managedObject: customerForExport)
            let ckRecord = icloudCustomer.makeFirstCloudKitRecord(self.cloudSalonReference)
            icloudCustomerRecords.append(ckRecord)
            totalCustomersToProcess++
        }
        return icloudCustomerRecords
    }
    func makeExportRecordsForCoredataEmployees() -> [CKRecord] {
        var icloudEmployeeRecords = [CKRecord]()
        for employeeForExport in coredataEmployeesNeedingExport() {
            if employeeForExport.isActive?.boolValue == NSNumber(bool: false) {
                // Only export active employees
                continue
            }
            let icloudEmployee = ICloudEmployee(managedObject: employeeForExport)
            let ckRecord = icloudEmployee.makeFirstCloudKitRecord(self.cloudSalonReference)
            icloudEmployeeRecords.append(ckRecord)
            totalEmployeesToProcess++
        }
        return icloudEmployeeRecords
    }
    func makeExportRecordsForCoredataServiceCategies() -> [CKRecord] {
        var icloudServiceCategoryRecords = [CKRecord]()
        for serviceCategoryForExport in coredataServiceCategoriesNeedingExport() {
            let icloudServiceCategory = ICloudServiceCategory(managedObject: serviceCategoryForExport)
            let ckRecord = icloudServiceCategory.makeFirstCloudKitRecord(self.cloudSalonReference)
            icloudServiceCategoryRecords.append(ckRecord)
            totalServiceCategoriesToProcess++
        }
        return icloudServiceCategoryRecords
    }
    func makeExportRecordsForCoredataServices() -> [CKRecord] {
        var icloudServiceRecords = [CKRecord]()
        for serviceForExport in coredataServicesNeedingExport() {
            if let parentCategory = serviceForExport.serviceCategory {
                let icloudService = ICloudService(managedObject: serviceForExport)
                let ckRecord = icloudService.makeFirstCloudKitRecord(self.cloudSalonReference)
                let metadata = parentCategory.bqMetadata!
                let unarchiver = NSKeyedUnarchiver(forReadingWithData:metadata)
                let serviceCategoryRecord = CKRecord(coder: unarchiver)!
                let serviceCategoryReference = CKReference(record: serviceCategoryRecord, action: CKReferenceAction.DeleteSelf)
                icloudService.serviceCategory = serviceCategoryReference
                icloudServiceRecords.append(ckRecord)
                totalServicesToProcess++
            }
        }
        return icloudServiceRecords
    }
    
    // MARK:- prepare coredata objects for export
    func prepareAllCustomersForCoredataExport() {
        allCoredataCustomers = Customer.customersOrderedByFirstName(moc)
        coredataCustomersDictionary.removeAll()
        for customer in allCoredataCustomers {
            let uid = BQDataExtractViewController.uidStringFromManagedObject(customer)
            coredataCustomersDictionary[uid] = customer
            customer.bqNeedsCoreDataExport = NSNumber(bool: true)
            customer.bqMetadata = nil
        }
    }
    func prepareAllEmployeesForCoredataExport() {
        allCoredataEmployees = Employee.employeesOrderedByFirstName(moc)
        coredataEmployeeDictionary.removeAll()
        for employee in allCoredataEmployees {
            let uid = BQDataExtractViewController.uidStringFromManagedObject(employee)
            coredataEmployeeDictionary[uid] = employee
            employee.bqNeedsCoreDataExport = NSNumber(bool: true)
            employee.bqMetadata = nil
        }
    }
    func prepareAllServiceCategoriesForCoredataExport() {
        allCoredataServiceCategories = ServiceCategory.serviceCategoriesOrderedByName(moc)
        coredataServiceCategoriesDictionary.removeAll()
        for serviceCategory in allCoredataServiceCategories {
            let uid = BQDataExtractViewController.uidStringFromManagedObject(serviceCategory)
            coredataServiceCategoriesDictionary[uid] = serviceCategory
            serviceCategory.bqNeedsCoreDataExport = NSNumber(bool: true)
            serviceCategory.bqMetadata = nil
        }
    }
    func prepareAllServicesForCoredataExport() {
        allCoredataServices = Service.servicesOrderedByName(moc)
        coredataServicesDictionary.removeAll()
        for service in allCoredataServices {
            let uid = BQDataExtractViewController.uidStringFromManagedObject(service)
            coredataServicesDictionary[uid] = service
            service.bqNeedsCoreDataExport = NSNumber(bool: true)
            service.bqMetadata = nil
        }
    }
    
    // MARK:- Create operation to extract top-level salon object
    func extractSalonOperation() -> CKModifyRecordsOperation {
        let cloudSalon = ICloudSalon(managedObject: self.salonDocument.salon)
        cloudSalonRecord = cloudSalon.makeFirstCloudkitRecord(nil)
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
                let coredataID = record!["coredataID"] as! String
                let metadata = archiveMetadataForCKRecord(record!)
                switch recordType {
                case ICloudRecordType.Customer.rawValue:
                    let coredataCustomer = self.coredataCustomersDictionary[coredataID]
                    coredataCustomer?.bqNeedsCoreDataExport = NSNumber(bool: false)
                    coredataCustomer?.bqMetadata = metadata
                    self.extractedCustomerCount++
                    self.customerProgressIndicator.doubleValue = Double(self.extractedCustomerCount) * 100.0 / Double(self.totalCustomersToProcess)
                case ICloudRecordType.Employee.rawValue:
                    let coredataEmployee = self.coredataEmployeeDictionary[coredataID]
                    coredataEmployee?.bqNeedsCoreDataExport = NSNumber(bool: false)
                    coredataEmployee?.bqMetadata = metadata
                    self.extractedEmployeesCount++
                    self.employeeProgressIndicator.doubleValue = Double(self.extractedEmployeesCount) * 100.0 / Double(self.totalEmployeesToProcess)
                case ICloudRecordType.ServiceCategory.rawValue:
                    let coredataServiceCategory = self.coredataServiceCategoriesDictionary[coredataID]
                    coredataServiceCategory?.bqNeedsCoreDataExport = NSNumber(bool: false)
                    coredataServiceCategory?.bqMetadata = metadata
                    self.extractedServiceCategoriesCount++
                    self.serviceCategoryProgressIndicator.doubleValue = Double(self.extractedServiceCategoriesCount) * 100.0 / Double(self.totalServiceCategoriesToProcess)
                    if self.extractedServiceCategoriesCount == self.totalServiceCategoriesToProcess {
                        // services are dependent on the serviceCategories operation because serviceCategories own services
                        let serviceRecords = self.makeExportRecordsForCoredataServices()
                        let servicesOperation = self.saveRecordsOperation(serviceRecords)
                        self.publicDatabase.addOperation(servicesOperation)
                    }
                case ICloudRecordType.Service.rawValue:
                    let coredataService = self.coredataServicesDictionary[coredataID]
                    coredataService?.bqNeedsCoreDataExport = NSNumber(bool: false)
                    coredataService?.bqMetadata = metadata
                    self.extractedServicesCount++
                    self.serviceProgressIndicator.doubleValue = Double(self.extractedServicesCount) * 100.0 / Double(self.totalServicesToProcess)
                default: break
                }
            }
        })
    }
    func saveRecordsOperation(customerRecords:[CKRecord]) -> CKModifyRecordsOperation {
        // Create the operation that we will return
        let saveOperation = CKModifyRecordsOperation(recordsToSave: customerRecords, recordIDsToDelete: nil)
        saveOperation.savePolicy = CKRecordSavePolicy.ChangedKeys
        
        // Record completes
        saveOperation.perRecordCompletionBlock = { (record:CKRecord?, error:NSError?) in self.recordWasSaved(record, error: error) }
        
        // All records complete
        saveOperation.modifyRecordsCompletionBlock = { (saveRecords:[CKRecord]?,deleteRecordIDs:[CKRecordID]?,error:NSError?) in
            guard let recordsToSave = saveOperation.recordsToSave else { return }
            if let error = error {
                if error.code == CKErrorCode.LimitExceeded.rawValue {
                    // Operation had too many records - need to recurse down to smaller operations
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
                saveOperation.dependencies
                    self.publicDatabase.addOperation(operationA)
                    self.publicDatabase.addOperation(operationB)
                } else {
                    assertionFailure("Unhandled error")
                }
                return
            }
            // UI operations must be on main queue
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                if self.totalCustomersToProcess == self.extractedCustomerCount {
                    self.activityIndicator.stopAnimation(self)
                    self.activityIndicator.hidden = true
                    self.extractStatus.stringValue = "Finished!"
                    do {
                        // We have some (possibly many) coredata changes that need to be saved
                        try self.salonDocument.managedObjectContext?.save()
                    } catch {
                        assertionFailure("Failed to save managed object after saving records to icloud")
                    }
                    do {
                        try self.moc.save()
                    } catch {
                        assertionFailure("failed to save moc")
                    }
                }
            })
        }
        return saveOperation
    }

    // MARK:- Helper functions
    class func uidStringFromManagedObject(managedObject:NSManagedObject) -> String {
        return managedObject.objectID.URIRepresentation().absoluteString
    }

}
