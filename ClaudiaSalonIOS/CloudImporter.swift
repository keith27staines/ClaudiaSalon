//
//  CloudImporter.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 12/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class BQCloudImporter {
    private lazy var synchQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    var downloads = [String:DownloadInfo]()
    var downloadWasUpdated: ((info:DownloadInfo) -> Void)?
    var downloadCompleted: ((info:DownloadInfo) -> Void)?
    var allDownloadsComplete: ((withErrors:[NSError]?)->Void)?

    private let publicDatabase = CKContainer(identifier: "iCloud.uk.co.ClaudiasSalon.ClaudiaSalon").publicCloudDatabase
    private let salonCloudRecordName = "44736040-37E7-46B0-AAAB-8EA90A6C99C4"
    private let cloudSalonReference : CKReference? = nil
    private var downloadedRecords = [CKRecord]()
    private var queryOperations = Set<CKQueryOperation>()
    private let moc = Coredata.sharedInstance.backgroundContext
    
    private var appointments = [(appointment:Appointment,record:CKRecord)]()
    private var customers = [(customer:Customer,record:CKRecord)]()
    private var employees = [(employee:Employee,record:CKRecord)]()
    private var sales = [(sale:Sale,record:CKRecord)]()
    private var saleItems = [(saleItem:SaleItem,record:CKRecord)]()
    private var salons = [(salon:Salon,record:CKRecord)]()
    private var services = [(service:Service,record:CKRecord)]()
    private var serviceCategories = [(serviceCategory:ServiceCategory,record:CKRecord)]()
    
    private (set) var cancelled = false
    
    init() {
        self.reinitialiseDatastructures()
    }
    
    private func reinitialiseDatastructures() {
        self.synchQueue.addOperationWithBlock() {
            self.downloadedRecords.removeAll(keepCapacity: true)
            self.downloads.removeAll()
            for recordType in CloudRecordType.typesAsArray() {
                let info = DownloadInfo(recordType: recordType)
                self.downloads[recordType.rawValue] = info
            }
            self.queryOperations.removeAll()
        }
    }
    
    func startImport() {
        self.synchQueue.addOperationWithBlock() {
            self.deleteAllCoredataObjects()
            for recordType in CloudRecordType.typesAsArray() {
                self.addQueryOperationToQueueForType(recordType)
            }
        }
    }
    func cancelImport() {
        self.synchQueue.addOperationWithBlock() {
            for operation in self.queryOperations {
                operation.cancel()
            }
            self.cancelled = true
        }
    }

    private func addQueryOperationToQueueForType(type:CloudRecordType) {
        let downloadInfoForType = DownloadInfo(recordType: type)
        downloads[type.rawValue] = downloadInfoForType
        let queryOperation = self.fetchRecordsFromCloudOperation(type.rawValue)
        self.ThreadSafeAddQueryOperationToQueue(queryOperation)
    }
    
    
    private func handleDownloadedRecord(operation:CKQueryOperation,record:CKRecord) {
        self.synchQueue.addOperationWithBlock() {
            self.downloadedRecords.append(record)
            guard let name = operation.name else {
                fatalError("Operation lacks a name and so cannot be processed")
            }
            guard var info = self.downloads[name] else {
                fatalError("The operation isn't recognised")
            }
            info.waiting = false
            info.executing = true
            info.recordsDownloaded += 1
            self.downloads[name] = info
            if let callback = self.downloadWasUpdated {
                callback(info: info)
            }
        }
    }
    
    private func handleQueryCompletion(operation:CKQueryOperation,cursor:CKQueryCursor?,error:NSError?) {
        self.synchQueue.addOperationWithBlock() {
            guard let name = operation.name else {
                fatalError("Operation lacks a name and so cannot be processed")
            }
            guard var info = self.downloads[name] else {
                fatalError("The operation isn't recognised")
            }
            info.activeOperations -= 1
            if info.activeOperations == 0 {
                info.waiting = false
                info.executing = false
                info.finished = true
            }
            info.error = error
            self.downloads[name] = info
            
            if let cursor = cursor  {
                if !self.cancelled {
                    let nextQueryOperation = CKQueryOperation(cursor: cursor)
                    nextQueryOperation.name = operation.name
                    nextQueryOperation.queryCompletionBlock = { cursor, error in
                        self.handleQueryCompletion(nextQueryOperation,cursor:cursor,error:error)
                    }
                    nextQueryOperation.recordFetchedBlock = { record in
                        self.handleDownloadedRecord(nextQueryOperation, record: record)
                    }
                    self.unsafeAddQueryOperationToQueue(nextQueryOperation)
                }
            }
            
            if self.downloads[name]!.activeOperations == 0 {
                if let callback = self.downloadCompleted {
                    callback(info: info)
                }
            }
            self.queryOperations.remove(operation)
            if self.cancelled {
                self.deleteAllCoredataObjects()
                self.reinitialiseDatastructures()
            }
            
            if self.downloadsDidCompleteSuccessfully() {
                print("Building database from \(self.downloadedRecords.count) downloaded records")
                self.createShallowCoredataObjectsFromCloudRecords(self.downloadedRecords)
                
                self.deepProcessSalon()
                self.deepProcessCustomers()
                self.deepProcessEmployees()

                self.deepProcessAppointments()
                self.deepProcessSales()
                self.deepProcessSaleItems()
                self.deepProcessServiceCategories()
                self.deepProcessServices()
                self.moc.performBlock() {
                    try! self.moc.save()
                    print("Save successful")
                }
            }
        }
    }
    func deepProcessSalon() {
        let r = salons[0]
        let salon = r.salon
        let record = r.record
        let anonymousCustomerReference = record["anonymousCustomerReference"] as! CKReference
        let anonymousCustomerCloudID = anonymousCustomerReference.recordID.recordName
        let rootServiceCategoryReference = record["rootServiceCategoryReference"] as! CKReference
        let rootServiceCategoryCloudID = rootServiceCategoryReference.recordID.recordName
        moc.performBlockAndWait() {
            let anonymousCustomer = Customer.fetchForCloudID(anonymousCustomerCloudID, moc: self.moc)
            let rootServiceCategory = ServiceCategory.fetchForCloudID(rootServiceCategoryCloudID, moc: self.moc)
            salon.anonymousCustomer = anonymousCustomer
            salon.rootServiceCategory = rootServiceCategory
        }
    }
    func deepProcessEmployees() {
        
    }
    func deepProcessCustomers() {
        
    }
    func deepProcessServiceCategories() {
        for r in serviceCategories {
            let category = r.serviceCategory
            let record = r.record
            if let reference = record["parentCategoryReference"] as? CKReference {
                let cloudID = reference.recordID.recordName
                moc.performBlockAndWait() {
                    let serviceCategory = ServiceCategory.fetchForCloudID(cloudID, moc: self.moc)
                    category.parent = serviceCategory
                }
            }
        }
    }
    func deepProcessServices() {
        for r in services {
            let service = r.service
            let record = r.record
            if let categoryReference = record["parentCategoryReference"] as? CKReference {
                let categoryID = categoryReference.recordID.recordName
                moc.performBlockAndWait() {
                    let parentCategory = ServiceCategory.fetchForCloudID(categoryID, moc: self.moc)
                    service.serviceCategory = parentCategory
                }
            }
        }
    }
    func deepProcessAppointments() {
        for r in appointments {
            let appointment = r.appointment
            let record = r.record
            let customerReference = record["parentCustomerReference"] as! CKReference
            let cloudID = customerReference.recordID.recordName
            moc.performBlockAndWait() {
                let parentCustomer = Customer.fetchForCloudID(cloudID, moc: self.moc)
                appointment.customer = parentCustomer
            }
        }
    }
    func deepProcessSales() {
        for r in sales {
            let sale = r.sale
            let record = r.record
            let customerReference = record["parentCustomerReference"] as! CKReference
            let customerCloudID = customerReference.recordID.recordName
            let appointmentReference = record["parentAppointmentReference"] as! CKReference
            let appointmentCloudID = appointmentReference.recordID.recordName
            moc.performBlockAndWait() {
                let customer = Customer.fetchForCloudID(customerCloudID, moc: self.moc)
                sale.customer = customer
                let appointment = Appointment.fetchForCloudID(appointmentCloudID, moc: self.moc)
                sale.fromAppointment = appointment
            }
        }
    }
    func deepProcessSaleItems() {
        for r in saleItems {
            let saleItem = r.saleItem
            let record = r.record
            moc.performBlockAndWait() {
                if let saleReference = record["parentSaleReference"] as? CKReference {
                    let saleCloudID = saleReference.recordID.recordName
                    let sale = Sale.fetchForCloudID(saleCloudID, moc: self.moc)
                    saleItem.sale = sale
                }
                if let serviceReference = record["serviceReference"] as? CKReference {
                    let serviceCloudID = serviceReference.recordID.recordName
                    let service = Service.fetchForCloudID(serviceCloudID, moc: self.moc)
                    saleItem.service = service
                }
                if let employeeReference = record["employeeReference"] as? CKReference {
                    let employeeCloudID = employeeReference.recordID.recordName
                    let employee = Employee.fetchForCloudID(employeeCloudID, moc: self.moc)
                    saleItem.performedBy = employee
                }
            }
        }
    }
    
    private func createShallowCoredataObjectsFromCloudRecords(records:[CKRecord]) {
        for record in records {
            let type = record.recordType
            let recordName = record.recordID.recordName
            let cType = CloudRecordType.typeFromCloudRecordType(type)
            
            moc.performBlockAndWait() {
                switch cType {
                case .CRAppointment:
                    var appointment:Appointment?
                    appointment = Appointment.fetchForCloudID(recordName, moc: self.moc)
                    if appointment == nil {
                        appointment = Appointment.newObjectWithMoc(self.moc)
                    }
                    appointment!.updateFromCloudRecordIfNeeded(record)
                    self.appointments.append((appointment!,record))
                case .CRCustomer:
                    var customer:Customer?
                    customer = Customer.fetchForCloudID(recordName, moc: self.moc)
                    if customer == nil {
                        customer = Customer.newObjectWithMoc(self.moc)
                    }
                    customer!.updateFromCloudRecordIfNeeded(record)
                    self.customers.append((customer!, record))
                case .CREmployee:
                    var employee:Employee?
                    employee = Employee.fetchForCloudID(recordName, moc: self.moc)
                    if employee == nil {
                        employee = Employee.newObjectWithMoc(self.moc)
                    }
                    employee!.updateFromCloudRecordIfNeeded(record)
                    self.employees.append((employee!, record))
                case .CRSale:
                    var sale:Sale?
                    sale = Sale.fetchForCloudID(recordName, moc: self.moc)
                    if sale == nil {
                        sale = Sale.newObjectWithMoc(self.moc)
                    }
                    sale!.updateFromCloudRecordIfNeeded(record)
                    self.sales.append((sale!,record))
                case .CRSaleItem:
                    var saleItem:SaleItem?
                    saleItem = SaleItem.fetchForCloudID(recordName, moc: self.moc)
                    if saleItem == nil {
                        saleItem = SaleItem.newObjectWithMoc(self.moc)
                    }
                    saleItem!.updateFromCloudRecordIfNeeded(record)
                    self.saleItems.append((saleItem!,record))
                case .CRSalon:
                    var salon:Salon?
                    salon = Salon.fetchForCloudID(recordName, moc: self.moc)
                    if salon == nil {
                        salon = Salon(moc:self.moc)
                    }
                    salon!.updateFromCloudRecordIfNeeded(record)
                    self.salons.append((salon!,record))
                case .CRService:
                    var service:Service?
                    service = Service.fetchForCloudID(recordName, moc: self.moc)
                    if service == nil {
                        service = Service.newObjectWithMoc(self.moc)
                    }
                    service!.updateFromCloudRecordIfNeeded(record)
                    self.services.append((service!,record))
                case .CRServiceCategory:
                    var serviceCategory:ServiceCategory?
                    serviceCategory = ServiceCategory.fetchForCloudID(recordName, moc: self.moc)
                    if serviceCategory == nil {
                        serviceCategory = ServiceCategory.newObjectWithMoc(self.moc)
                    }
                    serviceCategory!.updateFromCloudRecordIfNeeded(record)
                    self.serviceCategories.append((serviceCategory!,record))
                }
            }
        }
    }
    private func downloadsDidCompleteSuccessfully() -> Bool {
        if self.queryOperations.count > 0 { return false } // Some queries still running
        for (_,info) in self.downloads {
            if let _ = info.error { return false } // Finished but with an error
            if !info.finished { return false }  // Still running or waiting to run
        }
        // Everything finished without error
        return true
    }
    
    private func ThreadSafeAddQueryOperationToQueue(operation:CKQueryOperation) {
        self.synchQueue.addOperationWithBlock() {
            self.unsafeAddQueryOperationToQueue(operation)
        }
    }
    private func unsafeAddQueryOperationToQueue(operation:CKQueryOperation) {
        let recordType = operation.name!
        var info = self.downloads[recordType]!
        info.activeOperations += 1
        self.downloads[recordType] = info
        self.queryOperations.insert(operation)
        self.publicDatabase.addOperation(operation)
    }
}

extension BQCloudImporter {
    func fetchRecordsFromCloudOperation(recordType:String) -> CKQueryOperation {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.name = recordType
        queryOperation.queryCompletionBlock = { cursor, error in
            self.handleQueryCompletion(queryOperation,cursor:cursor,error:error)
        }
        queryOperation.recordFetchedBlock = { record in
            self.handleDownloadedRecord(queryOperation, record: record)
        }
        return queryOperation
    }
}

extension BQCloudImporter {
    func performInitialImport() {
        let salonRecordID = CKRecordID(recordName: self.salonCloudRecordName)
        self.publicDatabase.fetchRecordWithID(salonRecordID) { (record, error) -> Void in
            guard error == nil else {
                return
            }
            guard let record = record else {
                return
            }
            let moc = Coredata.sharedInstance.backgroundContext
            let salon = Salon.makeFromCloudRecord(record, moc: moc)
            if let anonCustomerRef = record["anonymousCustomerReference"] as? CKReference {
                let customerID = anonCustomerRef.recordID
                self.publicDatabase.fetchRecordWithID(customerID, completionHandler: { (customerRecord, error) -> Void in
                    if error != nil {
                        fatalError("Failed to download the Anonymous Customer from cloud")
                    } else {
                        if let anon = Customer.fetchForCloudID(customerID.recordName, moc: moc) {
                            anon.updateFromCloudRecordIfNeeded(customerRecord!)
                            salon.anonymousCustomer = anon
                        } else {
                            let anon = Customer.makeFromCloudRecord(customerRecord!, moc: moc)
                            salon.anonymousCustomer = anon
                        }
                    }
                    moc.performBlock() {
                        Coredata.sharedInstance.save()
                    }
                })
            }
        }
    }
    func deleteAllCoredataObjects() {
        let entities = ["Salon", "Customer", "Employee", "Service", "ServiceCategory", "Appointment", "Sale", "SaleItem"]
        for entity in entities {
            self.deleteEntity(entity)
        }
        Coredata.sharedInstance.save()
    }
    func deleteEntity(name:String) {
        let fetchRequest = NSFetchRequest(entityName: name)
        let yesPredicate = NSPredicate(value: true)
        fetchRequest.predicate = yesPredicate
        let moc = Coredata.sharedInstance.backgroundContext
        moc.performBlockAndWait() {
            let fetchedObjects = try! moc.executeFetchRequest(fetchRequest)
            for modelObject in fetchedObjects {
                moc.deleteObject(modelObject as! NSManagedObject)
            }
        }
    }
}
