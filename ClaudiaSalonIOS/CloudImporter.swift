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
@objc
class BQCloudImporter : NSObject {
    private lazy var synchQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    var downloads = [String:DownloadInfo]()
    var downloadWasUpdated: ((info:DownloadInfo) -> Void)?
    var downloadCompleted: ((info:DownloadInfo) -> Void)?
    var allDownloadsComplete: ((withErrors:[NSError]?)->Void)?

    private var container:CKContainer!
    private var publicDatabase: CKDatabase!
    private let salonCloudRecordName : String!

    private var downloadedRecords = [CKRecord]()
    private var queryOperations = Set<CKQueryOperation>()
    
    private var appointments = [(appointment:Appointment,record:CKRecord)]()
    private var customers = [(customer:Customer,record:CKRecord)]()
    private var employees = [(employee:Employee,record:CKRecord)]()
    private var sales = [(sale:Sale,record:CKRecord)]()
    private var saleItems = [(saleItem:SaleItem,record:CKRecord)]()
    private var salons = [(salon:Salon,record:CKRecord)]()
    private var services = [(service:Service,record:CKRecord)]()
    private var serviceCategories = [(serviceCategory:ServiceCategory,record:CKRecord)]()
    private var accounts = [(account:Account,record:CKRecord)]()
    
    private (set) var cancelled = false
    private (set) var cloudNotificationProcessor:CloudNotificationProcessor!
    private var moc:NSManagedObjectContext!
    private let parentMoc: NSManagedObjectContext
    
    init(parentMoc:NSManagedObjectContext,containerIdentifier:String, salonCloudRecordName:String) {
        self.parentMoc = parentMoc
        self.salonCloudRecordName = salonCloudRecordName
        self.container = CKContainer(identifier: containerIdentifier)
        self.publicDatabase = self.container.publicCloudDatabase
        self.cloudNotificationProcessor = CloudNotificationProcessor(cloudContainerIdentifier: containerIdentifier, cloudSalonRecordName: salonCloudRecordName)
        super.init()
        self.makePrivateMoc()
        self.cloudNotificationProcessor.moc = self.moc
        self.initialiseDatastructures()
    }
    
    func makePrivateMoc() {
        self.moc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.moc.parentContext = self.parentMoc
    }
    
    func forgetSalon(completion:(success:Bool)->Void) {
        self.cloudNotificationProcessor.forgetSalon { (success) in
            completion(success: success)
        }
    }

    func deleteSubscriptions(completion:(success:Bool)->Void) {
        self.cloudNotificationProcessor.cloudSubscriber.deleteSubscriptions { (success) in
            completion(success: success)
        }
    }
    func isSuspended() -> Bool {
        return self.cloudNotificationProcessor?.isSuspended() ?? true
    }
    
    func suspendCloudNotificationProcessing() {
        self.cloudNotificationProcessor.suspendNotificationProcessing()
    }
    func resumeCloudNotificationProcessing() {
        self.cloudNotificationProcessor.resumeNotificationProcessing()
    }
    
    func pollForMissedRemoteNotifications() {
        self.cloudNotificationProcessor.pollForMissedRemoteNotifications()
    }
    
    private func initialiseDatastructures() {
        self.synchQueue.addOperationWithBlock() {
            self.downloadedRecords.removeAll(keepCapacity: true)
            self.downloads.removeAll()
            for recordType in ICloudRecordType.typesAsArray() {
                let info = DownloadInfo(recordType: recordType)
                self.downloads[recordType.rawValue] = info
            }
            self.queryOperations.removeAll()
            
            self.salons.removeAll()
            self.employees.removeAll()
            self.customers.removeAll()
            self.services.removeAll()
            self.serviceCategories.removeAll()
            self.appointments.removeAll()
            self.sales.removeAll()
            self.saleItems.removeAll()
        }
    }
    
    func startBulkImport() {
        self.initialiseDatastructures()
        self.synchQueue.addOperationWithBlock() {
            self.cloudNotificationProcessor.suspendNotificationProcessing()
            self.deleteAllCoredataObjects()
            self.makePrivateMoc()
            for cloudRecordType in ICloudRecordType.typesAsArray() {
                self.addQueryOperationToQueueForType(cloudRecordType)
            }
        }
    }
    func cancelBulkImport() {
        self.synchQueue.addOperationWithBlock() {
            for operation in self.queryOperations {
                operation.cancel()
            }
            self.cancelled = true
        }
    }

    private func addQueryOperationToQueueForType(cloudRecordType:ICloudRecordType) {
        let downloadInfoForType = DownloadInfo(recordType: cloudRecordType)
        downloads[cloudRecordType.rawValue] = downloadInfoForType
        let queryOperation = self.fetchRecordsFromCloudOperation(cloudRecordType.rawValue)
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
                self.initialiseDatastructures()
            }
            
            if self.downloadsDidCompleteSuccessfully() {
                self.createShallowCoredataObjectsFromCloudRecords(self.downloadedRecords)
                self.deepProcessRecords()
                self.moc.performBlock() {
                    try! self.moc.save()
                }
                print("Built database from \(self.downloadedRecords.count) downloaded records")
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    if let callback = self.allDownloadsComplete {
                        callback(withErrors: nil)
                        self.cloudNotificationProcessor.resumeNotificationProcessing()
                    }
                }
            }
        }
    }
    func processDownloadedRecords() {
        self.createShallowCoredataObjectsFromCloudRecords(self.downloadedRecords)
        self.deepProcessRecords()
    }
    
    func deepProcessRecords() {
        self.deepProcessSalon()
        self.deepProcessCustomers()
        self.deepProcessEmployees()
        self.deepProcessAppointments()
        self.deepProcessSales()
        self.deepProcessSaleItems()
        self.deepProcessServiceCategories()
        self.deepProcessServices()
    }
    
    func deepProcessSalon() {
        let r = salons[0]
        self.deepProcessSalonRecord(r)
    }
    func deepProcessSalonRecord(r: (salon:Salon, record:CKRecord))  -> Bool {
        var result = false
        let salon = r.salon
        let record = r.record
        let anonymousCustomerReference = record["anonymousCustomerReference"] as! CKReference
        let anonymousCustomerCloudID = anonymousCustomerReference.recordID.recordName
        let rootServiceCategoryReference = record["rootServiceCategoryReference"] as! CKReference
        let rootServiceCategoryCloudID = rootServiceCategoryReference.recordID.recordName
        moc.performBlockAndWait() {
            if let anonymousCustomer = Customer.fetchForCloudID(anonymousCustomerCloudID, moc: self.moc),
                let rootServiceCategory = ServiceCategory.fetchForCloudID(rootServiceCategoryCloudID, moc: self.moc) {
                salon.anonymousCustomer = anonymousCustomer
                salon.rootServiceCategory = rootServiceCategory
                result = true
            }
        }
        return result
    }
    
    func deepProcessEmployees() {
        for r in employees {
            self.deepProcessEmployeeRecord(r)
        }
    }
    func deepProcessEmployeeRecord(r: (employee:Employee, record:CKRecord))  -> Bool {
        return true
    }
    
    func deepProcessCustomers() {
        for r in customers {
            self.deepProcessCustomerRecord(r)
        }
    }
    func deepProcessCustomerRecord(r: (customer:Customer, record:CKRecord))  -> Bool {
        return true
    }
    func deepProcessAccounts() {
        for r in accounts {
            self.deepProcessAccountRecord(r)
        }
    }
    func deepProcessAccountRecord(r: (account:Account, record:CKRecord)) -> Bool {
        assertionFailure("deepProcessAccounts function is not implemented")
        return false
    }
    
    func deepProcessBQExportable(bqExportable:BQExportable, record:CKRecord) -> Bool {
        let cloudRecordType = ICloudRecordType(rawValue: record.recordType)!
        let bqExportableType = cloudRecordType.bqExportableType()
        let managedObject = bqExportable as! NSManagedObject
        guard bqExportableType == managedObject.dynamicType else { fatalError("Coredata type and cloud record type are inconsistent")}
        switch cloudRecordType {
        case .CRAccount:         return deepProcessAccountRecord((bqExportable as! Account, record))
        case .CRAppointment:     return deepProcessAppointmentRecord((bqExportable as! Appointment, record))
        case .CRCustomer:        return deepProcessCustomerRecord((bqExportable as! Customer, record))
        case .CREmployee:        return deepProcessEmployeeRecord((bqExportable as! Employee, record))
        case .CRSale:            return deepProcessSaleRecord((bqExportable as! Sale, record))
        case .CRSaleItem:        return deepProcessSaleItemRecord((bqExportable as! SaleItem, record))
        case .CRSalon:           return deepProcessSalonRecord((bqExportable as! Salon, record))
        case .CRService:         return deepProcessServiceRecord((bqExportable as! Service, record))
        case .CRServiceCategory: return deepProcessServiceCategoryRecord((bqExportable as! ServiceCategory, record))
        }
    }
    
    func deepProcessServiceCategories() {
        for r in serviceCategories {
            self.deepProcessServiceCategoryRecord(r)
        }
    }

    func deepProcessServiceCategoryRecord(r: (serviceCategory:ServiceCategory, record:CKRecord)) -> Bool {
        var result = false
        let category = r.serviceCategory
        let record = r.record
        if let reference = record["parentCategoryReference"] as? CKReference {
            let cloudID = reference.recordID.recordName
            moc.performBlockAndWait() {
                if let serviceCategory = ServiceCategory.fetchForCloudID(cloudID, moc: self.moc) {
                    category.parent = serviceCategory
                    result = true
                }
            }
        } else {
            category.parent = nil
            result = true
        }
        return result
    }
    
    func deepProcessServices() {
        for r in services {
            self.deepProcessServiceRecord(r)
        }
    }
    func deepProcessServiceRecord(r: (service:Service, record:CKRecord))  -> Bool {
        var result = false
        let service = r.service
        let record = r.record
        if let categoryReference = record["parentCategoryReference"] as? CKReference {
            let categoryID = categoryReference.recordID.recordName
            moc.performBlockAndWait() {
                if let parentCategory = ServiceCategory.fetchForCloudID(categoryID, moc: self.moc) {
                    service.serviceCategory = parentCategory
                    result = true
                }
            }
        } else {
            service.serviceCategory = nil
            result = true
        }
        return result
    }
    
    func deepProcessAppointments() {
        for r in appointments {
            self.deepProcessAppointmentRecord(r)
        }
    }
    func deepProcessAppointmentRecord(r: (appointment:Appointment, record:CKRecord)) -> Bool {
        var result = false
        let appointment = r.appointment
        let record = r.record
        let customerReference = record["parentCustomerReference"] as! CKReference
        let customerCloudRecordName = customerReference.recordID.recordName
        moc.performBlockAndWait() {
            if let parentCustomer = Customer.fetchForCloudID(customerCloudRecordName, moc: self.moc) {
                appointment.customer = parentCustomer
                result = true
            }
        }
        return result
    }

    func deepProcessSales() {
        for r in sales {
            self.deepProcessSaleRecord(r)
        }
    }
    func deepProcessSaleRecord(r: (sale:Sale, record:CKRecord))  -> Bool {
        var result = false
        let sale = r.sale
        let record = r.record
        let customerReference = record["parentCustomerReference"] as! CKReference
        let customerCloudID = customerReference.recordID.recordName
        let appointmentReference = record["parentAppointmentReference"] as! CKReference
        let appointmentCloudID = appointmentReference.recordID.recordName
        moc.performBlockAndWait() {
            if let customer = Customer.fetchForCloudID(customerCloudID, moc: self.moc) {
                sale.customer = customer
            } else {
                result = false
            }
            if let appointment = Appointment.fetchForCloudID(appointmentCloudID, moc: self.moc) {
                sale.fromAppointment = appointment
            } else {
                result = false
            }
        }
        return result
    }
    func deepProcessSaleItems() {
        for r in saleItems {
            self.deepProcessSaleItemRecord(r)
        }
    }
    
    func deepProcessSaleItemRecord(r: (saleItem:SaleItem, record:CKRecord))  -> Bool {
        var result = false
        let saleItem = r.saleItem
        let record = r.record
        moc.performBlockAndWait() {
            if let saleReference = record["parentSaleReference"] as? CKReference {
                let saleCloudID = saleReference.recordID.recordName
                if let sale = Sale.fetchForCloudID(saleCloudID, moc: self.moc) {
                    saleItem.sale = sale
                    result = true
                } else {
                    // failed to find the sale this saleItem is currently assigned to
                    result = false
                }
            } else {
                // saleItem isn't assigned to a sale (NB currently, only saleItems deleted from a sale fall into this category)
                result = true
            }
            
            // If everything ok so far, go ahead and try to assign employee and service references
            result = false
            if let serviceReference = record["serviceReference"] as? CKReference {
                let serviceCloudID = serviceReference.recordID.recordName
                let service = Service.fetchForCloudID(serviceCloudID, moc: self.moc)
                saleItem.service = service
                result = true
            }
            if let employeeReference = record["employeeReference"] as? CKReference {
                let employeeCloudID = employeeReference.recordID.recordName
                let employee = Employee.fetchForCloudID(employeeCloudID, moc: self.moc)
                saleItem.performedBy = employee
            }
        }
        return result
    }
    
    private func deepProcessRecord(record:CKRecord) -> Bool {
        let type = record.recordType
        let recordName = record.recordID.recordName
        let cloudRecordType = ICloudRecordType.typeFromCloudRecordType(type)
        var result = false
        var bqExportable: BQExportable?
        moc.performBlockAndWait() {
            switch cloudRecordType {
            case .CRAppointment:
                if let appointment = Appointment.fetchForCloudID(recordName, moc: self.moc) {
                    bqExportable = appointment
                    result = self.deepProcessAppointmentRecord((appointment, record))
                } else {
                    result = false
                }
            case .CRCustomer:
                if let customer = Customer.fetchForCloudID(recordName, moc: self.moc) {
                    bqExportable = customer
                    result = self.deepProcessCustomerRecord((customer, record))
                } else {
                    result = false
                }
            case .CREmployee:
                if let employee = Employee.fetchForCloudID(recordName, moc: self.moc) {
                    bqExportable = employee
                    result = self.deepProcessEmployeeRecord((employee, record))
                } else {
                    result = false
                }
            case .CRSale:
                if let sale = Sale.fetchForCloudID(recordName, moc: self.moc) {
                    bqExportable = sale
                    result = self.deepProcessSaleRecord((sale, record))
                } else {
                    result = false
                }
            case .CRSaleItem:
                if let saleItem = SaleItem.fetchForCloudID(recordName, moc: self.moc) {
                    bqExportable = saleItem
                    result = self.deepProcessSaleItemRecord((saleItem, record))
                } else {
                    result = false
                }
            case .CRSalon:
                if let salon = Salon.fetchForCloudID(recordName, moc: self.moc) {
                    bqExportable = salon
                    result = self.deepProcessSalonRecord((salon, record))
                } else {
                    result = false
                }
            case .CRService:
                if let service = Service.fetchForCloudID(recordName, moc: self.moc) {
                    bqExportable = service
                    result = self.deepProcessServiceRecord((service, record))
                } else {
                    result = false
                }
            case .CRServiceCategory:
                if let serviceCategory = ServiceCategory.fetchForCloudID(recordName, moc: self.moc) {
                    bqExportable = serviceCategory
                    result = self.deepProcessServiceCategoryRecord((serviceCategory, record))
                } else {
                    result = false
                }
            case .CRAccount:
                if let bqExportable = cloudRecordType.bqExportableType().fetchBQExportable(recordName, moc: self.moc) {
                    result = self.deepProcessBQExportable(bqExportable, record: record)
                } else {
                    result = false
                }
            }
            if result == true {
                bqExportable?.bqNeedsCoreDataExport = false
                bqExportable?.bqHasClientChanges = false
            }
            
            try! self.moc.save()
            NSNotificationCenter.defaultCenter().postNotificationName("fetchedCloudNotificationsWereProcessedNotification", object: self)
        }
        return result
    }
    
    private func shallowProcessRecord(record:CKRecord) {
        let type = record.recordType
        let recordName = record.recordID.recordName
        let cloudRecordType = ICloudRecordType.typeFromCloudRecordType(type)
        
        moc.performBlockAndWait() {
            switch cloudRecordType {
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
                assert(salon?.managedObjectContext != nil)
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
            case .CRAccount:
                let exportableType = cloudRecordType.bqExportableType()
                let bqExportable = exportableType.fetchOrCreateBQExportable(recordName, moc: self.moc)
                bqExportable.updateFromCloudRecord(record)
                self.accounts.append((bqExportable as! Account, record))
            }
            try! self.moc.save()
        }
    }

    private func createShallowCoredataObjectsFromCloudRecords(records:[CKRecord]) {
        for record in records {
            self.shallowProcessRecord(record)
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

extension BQCloudImporter : RobustImporterDelegate {
    func importDidFail(importer:RobustImporter) {
        
    }
    func importDidProgressState(importer:RobustImporter) {
        
    }
}

extension BQCloudImporter {
    func fetchRecordsFromCloudOperation(recordType:String) -> CKQueryOperation {
        let salonID = CKRecordID(recordName: self.salonCloudRecordName)
        let salonRef = CKReference(recordID: salonID, action: .None)
        let predicate:NSPredicate
        let iType = ICloudRecordType(rawValue: recordType)!
        switch iType {
        case ICloudRecordType.CRSalon:
            predicate = NSPredicate(format: "self.recordID = %@", salonID)
        default:
            predicate = NSPredicate(format: "parentSalonReference = %@", salonRef)
        }
        let query = CKQuery(recordType: recordType, predicate: predicate)
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
            let salon = Salon.makeFromCloudRecord(record, moc: self.moc)
            if let anonCustomerRef = record["anonymousCustomerReference"] as? CKReference {
                let customerID = anonCustomerRef.recordID
                self.publicDatabase.fetchRecordWithID(customerID, completionHandler: { (customerRecord, error) -> Void in
                    if error != nil {
                        fatalError("Failed to download the Anonymous Customer from cloud")
                    } else {
                        if let anon = Customer.fetchForCloudID(customerID.recordName, moc: self.moc) {
                            anon.updateFromCloudRecordIfNeeded(customerRecord!)
                            salon.anonymousCustomer = anon
                        } else {
                            let anon = Customer.makeFromCloudRecord(customerRecord!, moc: self.moc)
                            salon.anonymousCustomer = anon
                        }
                    }
                    self.moc.performBlock() {
                        try! self.moc.save()
                    }
                })
            }
        }
    }
    func deleteAllCoredataObjects() {
        print("Deleting Coredata objects")
        let entities = ["Salon", "Customer", "Employee", "Service", "ServiceCategory", "Appointment", "Sale", "SaleItem"]
        for entity in entities {
            self.deleteEntity(entity)
        }
        try! self.moc.save()
        Coredata.sharedInstance.save()
        print("All Coredata objects were deleted")
    }
    func deleteEntity(name:String) {
        let fetchRequest = NSFetchRequest(entityName: name)
        let yesPredicate = NSPredicate(value: true)
        fetchRequest.predicate = yesPredicate
        self.moc.performBlockAndWait() {
            let fetchedObjects = try! self.moc.executeFetchRequest(fetchRequest)
            for modelObject in fetchedObjects {
                self.moc.deleteObject(modelObject as! NSManagedObject)
            }
        }
    }
}
