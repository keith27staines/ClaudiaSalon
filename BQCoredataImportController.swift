//
//  BQCoredataImportController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class BQCoredataImportController {
    
    static let publicDatabase = CKContainer(identifier: "iCloud.uk.co.ClaudiasSalon.ClaudiaSalon").publicCloudDatabase
    
    let salonCloudRecordName = "44736040-37E7-46B0-AAAB-8EA90A6C99C4"
    let publicDatabase: CKDatabase
    let coredata = Coredata.sharedInstance
    let parentSalonRecordID:CKRecordID
    let parentSalonReference:CKReference
    var finished = false
    private let counter = AMCThreadSafeCounter(name: "coredataImporter", initialValue: 0)
    
    init() {
        parentSalonRecordID = CKRecordID(recordName: salonCloudRecordName)
        parentSalonReference = CKReference(recordID: parentSalonRecordID, action: .None)
        publicDatabase = BQCoredataImportController.publicDatabase
        let salon = Salon.fetchForCloudID(salonCloudRecordName, moc: Coredata.sharedInstance.backgroundContext)
        
        if let salon = salon {
            let salonCloudRecordID = CKRecordID(recordName: salonCloudRecordName)
            self.publicDatabase.fetchRecordWithID(salonCloudRecordID) { (salonRecord, error) -> Void in
                if error != nil {
                    fatalError("error downloading salon from cloud")
                } else {
                    salon.updateFromCloudRecordIfNeeded(salonRecord!)
                }
            }
        } else {
            self.performInitialImport()
        }
    }
    
    func fetchCloudAppointments() {
        let queryOperation = self.queryOperationForAppointments()
        counter.increment()
        publicDatabase.addOperation(queryOperation)
    }
    func queryOperationForAppointments()->CKQueryOperation {
        let earliestDate = NSDate().dateByAddingTimeInterval(-30*24*3600);
        let predicate = NSPredicate(format: "appointmentStartDate >= %@ AND parentSalonReference = %@", earliestDate,self.parentSalonReference)
        let query = CKQuery(recordType: "icloudAppointment", predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = 100
        queryOperation.recordFetchedBlock = {  record in
            self.processDownloadedAppointment(record)
        }
        queryOperation.queryCompletionBlock = { (cursor, error) in
            if queryOperation.cancelled {
                return
            }
            if error != nil {
                print("Error fetching appointments \(error)")
            }
            if let cursor = cursor {
                let nextBatch = CKQueryOperation(cursor: cursor)
                nextBatch.queryCompletionBlock = queryOperation.queryCompletionBlock
                nextBatch.recordFetchedBlock = queryOperation.recordFetchedBlock
                self.counter.increment()
                self.publicDatabase.addOperation(nextBatch)
            }
        }
        return queryOperation
    }
    func processDownloadedAppointment(appointmentRecord:CKRecord) {
        let cloudID = appointmentRecord.recordID.recordName
        let moc = coredata.backgroundContext
        moc.performBlock() {
            var appointment = Appointment.fetchForCloudID(cloudID, moc: moc)
            if let appointment = appointment {
                appointment.updateFromCloudRecordIfNeeded(appointmentRecord)
            } else {
                appointment = Appointment.makeFromCloudRecord(appointmentRecord, moc: moc)
            }
            let fillOperations = self.fillAppointmentDetailsOperations(appointment!, appointmentRecord: appointmentRecord)
            for operation in fillOperations {
                self.publicDatabase.addOperation(operation)
            }
        }
    }
}

extension BQCoredataImportController {
    func performInitialImport() {
        // Start from clean slate
        self.deleteAllCoredataObjects()
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
                        Coredata.sharedInstance.saveContext()
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
        self.coredata.saveContext()
    }
    func deleteEntity(name:String) {
        let fetchRequest = NSFetchRequest(entityName: name)
        let yesPredicate = NSPredicate(value: true)
        fetchRequest.predicate = yesPredicate
        let moc = self.coredata.backgroundContext
        moc.performBlockAndWait() {
            let fetchedObjects = try! moc.executeFetchRequest(fetchRequest)
            for modelObject in fetchedObjects {
                moc.deleteObject(modelObject as! NSManagedObject)
            }
        }
    }
}

extension BQCoredataImportController {
    func fillAppointmentDetailsOperations(appointment:Appointment, appointmentRecord:CKRecord) -> [CKQueryOperation] {
        let customerOperation = CustomerForAppointmentOperation(appointment: appointment, appointmentRecord: appointmentRecord)
        
        let saleOperation = SaleForAppointmentOperation(appointment: appointment, appointmentRecord: appointmentRecord)
        saleOperation.addDependency(customerOperation)

        //let saleItemsOperation = SaleItemsForSaleOperation()
        //saleItemsOperation.addDependency(saleOperation)
        //return [customerOperation,saleOperation,saleItemsOperation]
        
        return [customerOperation, saleOperation]
    }
}

protocol AppointmentBuilder {
    var error: NSError? { get }
    var appointment: Appointment? { get }
}
class SaleForAppointmentOperation : CKQueryOperation, AppointmentBuilder {
    var error: NSError?
    private (set) var appointment:Appointment?
    private (set) var appointmentRecord:CKRecord
    private (set) var saleRecord: CKRecord?
    
    init(appointment:Appointment, appointmentRecord:CKRecord) {
        self.appointment = appointment
        self.appointmentRecord = appointmentRecord
        let appointmentRef = CKReference(record: appointmentRecord, action: .None)
        let predicate = NSPredicate(format: "parentAppointmentReference == %@", appointmentRef)
        super.init()
        query = CKQuery(recordType: "iCloudSale", predicate: predicate)
        super.recordFetchedBlock = { record in
            self.saleRecord = record
            let moc = appointment.managedObjectContext!
            moc.performBlockAndWait() {
                if let sale = Sale.fetchForCloudID(record.recordID.recordName, moc: moc) {
                    sale.updateFromCloudRecordIfNeeded(record)
                    appointment.sale = sale
                } else {
                    appointment.sale = Sale.makeFromCloudRecord(record, moc: moc)
                }
            }
            Coredata.sharedInstance.saveContext()
        }
        self.queryCompletionBlock  = { (queryCursor, error) in
            guard error == nil else {
                self.error = error
                assertionFailure("error while fetching appointment's customer \(error)")
                return
            }
        }
    }
}

class ServiceForSaleItem : CKQueryOperation, AppointmentBuilder {
    var error: NSError?
    private (set) var appointment:Appointment?
    private (set) var serviceRecord:CKRecord?
    
    init(saleItem:SaleItem,saleItemRecord:CKRecord) {
        self.appointment = saleItem.sale?.fromAppointment
        super.init()
        self.queryCompletionBlock  = { (queryCursor, error) in
            guard error == nil else {
                self.error = error
                assertionFailure("error while fetching service for saleItem \(error)")
                return
            }
        }
        let serviceRef = saleItemRecord["serviceReference"] as? CKReference
        guard let serviceID = serviceRef?.recordID else {
            return
        }
        let predicate = NSPredicate(format: "recordID == %@", serviceID)
        query = CKQuery(recordType: "iCloudService", predicate: predicate)
        self.recordFetchedBlock = { serviceRecord in
            self.serviceRecord = serviceRecord
            let moc = saleItem.managedObjectContext!
            moc.performBlockAndWait() {
                if let service = Service.fetchForCloudID(serviceRecord.recordID.recordName, moc: moc) {
                    service.updateFromCloudRecordIfNeeded(serviceRecord)
                    saleItem.service = service
                } else {
                    saleItem.service = Service.makeFromCloudRecord(serviceRecord, moc: moc)
                }
            }
            Coredata.sharedInstance.saveContext()
        }
    }
}

class EmployeeForSaleItem : CKQueryOperation, AppointmentBuilder {
    var error: NSError?
    private (set) var appointment:Appointment?
    private (set) var employeeRecord:CKRecord?
    
    init(saleItem:SaleItem,saleItemRecord:CKRecord) {
        self.appointment = saleItem.sale?.fromAppointment
        super.init()
        self.queryCompletionBlock  = { (queryCursor, error) in
            guard error == nil else {
                self.error = error
                assertionFailure("error while fetching service for saleItem \(error)")
                return
            }
        }
        let employeeRef = saleItemRecord["employeeReference"] as? CKReference
        guard let employeeID = employeeRef?.recordID else {
            return
        }
        let predicate = NSPredicate(format: "recordID == %@", employeeID)
        query = CKQuery(recordType: "iCloudEmployee", predicate: predicate)
        self.recordFetchedBlock = { employeeRecord in
            self.employeeRecord = employeeRecord
            let moc = saleItem.managedObjectContext!
            moc.performBlockAndWait() {
                if let employee = Employee.fetchForCloudID(employeeRecord.recordID.recordName, moc: moc) {
                    employee.updateFromCloudRecordIfNeeded(employeeRecord)
                    saleItem.performedBy = employee
                } else {
                    saleItem.performedBy = Employee.makeFromCloudRecord(employeeRecord, moc: moc)
                }
            }
            Coredata.sharedInstance.saveContext()
        }
    }
}

class SaleItemsForSaleOperation : CKQueryOperation, AppointmentBuilder {
    var error: NSError?
    private (set) var appointment:Appointment?
    private (set) var sale:Sale
    private (set) var saleRecord: CKRecord?
    private var saleItemsFromCloud = Set<SaleItem>()
    private let synchQueue = NSOperationQueue()
    private let moc: NSManagedObjectContext
    
    init(sale:Sale) {
        self.sale = sale
        self.moc = sale.managedObjectContext!
        super.init()

        self.moc.performBlockAndWait() {
            self.appointment = sale.fromAppointment
            self.saleRecord = sale.cloudkitRecordFromEmbeddedMetadata()
        }
        guard let saleRecord = self.saleRecord else {
            return
        }
        let saleRef = CKReference(record: saleRecord, action: .None)
        let predicate = NSPredicate(format: "parentSaleReference == %@", saleRef)
        query = CKQuery(recordType: "iCloudSaleItem", predicate: predicate)
        self.recordFetchedBlock = { record in
            var saleItem:SaleItem?
            self.moc.performBlockAndWait() {
                if let existingSaleItem = SaleItem.fetchForCloudID(record.recordID.recordName, moc: self.moc) {
                    saleItem = existingSaleItem
                    existingSaleItem.updateFromCloudRecordIfNeeded(record)
                } else {
                    let newSaleItem = SaleItem.makeFromCloudRecord(record, moc: self.moc)
                    saleItem = newSaleItem
                }
                if let saleItem = saleItem {
                    self.synchQueue.addOperationWithBlock() { self.saleItemsFromCloud.insert(saleItem) }
                    BQCoredataImportController.publicDatabase.addOperation(ServiceForSaleItem(saleItem: saleItem, saleItemRecord: record))
                    BQCoredataImportController.publicDatabase.addOperation(EmployeeForSaleItem(saleItem: saleItem, saleItemRecord: record))
                }
            }
        }
        self.queryCompletionBlock  = { (queryCursor, error) in
            guard error == nil else {
                self.error = error
                assertionFailure("error while fetching saleItems \(error)")
                return
            }
            self.moc.performBlockAndWait() {
                let currentItems = self.sale.saleItem!
                for saleItem in currentItems {
                    if !self.saleItemsFromCloud.contains(saleItem) {
                        self.sale.removeSaleItemObject(saleItem)
                        self.moc.deleteObject(saleItem)
                    }
                }
                for saleItem in self.saleItemsFromCloud {
                    self.sale.addSaleItemObject(saleItem)
                }
            }
            Coredata.sharedInstance.saveContext()
        }
    }
}
class CustomerForAppointmentOperation : CKQueryOperation, AppointmentBuilder {
    var error: NSError?
    private (set) var appointment:Appointment?
    private (set) var appointmentRecord:CKRecord
    private (set) var customerRecord: CKRecord?
    
    init(appointment:Appointment, appointmentRecord:CKRecord) {
        self.appointment = appointment
        self.appointmentRecord = appointmentRecord
        let customerRef = appointmentRecord["parentCustomerReference"] as! CKReference
        let predicate = NSPredicate(format: "recordID == %@", customerRef.recordID)
        super.init()
        query = CKQuery(recordType: "iCloudCustomer", predicate: predicate)
        super.recordFetchedBlock = { record in
            self.customerRecord = record
            let moc = Coredata.sharedInstance.backgroundContext
            moc.performBlockAndWait() {
                if let customer = Customer.fetchForCloudID(record.recordID.recordName, moc: moc) {
                    customer.updateFromCloudRecordIfNeeded(record)
                    appointment.customer = customer
                } else {
                    appointment.customer = Customer.makeFromCloudRecord(record, moc: moc)
                }
            }
        }
        self.queryCompletionBlock  = { (queryCursor, error) in
            guard error == nil else {
                self.error = error
                assertionFailure("error while fetching appointment's customer \(error)")
                return
            }
            Coredata.sharedInstance.saveContext()
        }
    }
}
extension BQExportable {
    func doesNeedUpdateFromCloud(cloudRecord:CKRecord) -> Bool {
        guard let metadata = self.bqMetadata else {
            return true // We have never been initialised with any data from the cloud
        }
        let decoder = NSKeyedUnarchiver(forReadingWithData: metadata)
        guard let _ = CKRecord(coder: decoder) else {
            print("Unable to decode the cloud record from the supplied metadata")
            return true
        }
        guard let lastUpdatedDate = self.lastUpdatedDate else {
            return true
        }
        if cloudRecord.modificationDate!.isGreaterThan(lastUpdatedDate) {
            return true
        }
        return false  // We don't need to update ourself as we are more recent
    }
    func updateFromCloudRecordIfNeeded(record:CKRecord) {
        if self.doesNeedUpdateFromCloud(record) {
            self.updateFromCloudRecord(record)
        }
    }
}
extension CKRecord {
    func metadataFromRecord() -> NSData {
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWithMutableData: data)
        self.encodeSystemFieldsWithCoder(coder)
        coder.finishEncoding()
        return data
    }
}


extension Sale {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Sale {
        var sale: Sale!
        moc.performBlockAndWait() {
            precondition(record.recordType == "icloudSale", "Unable to create a customer from this record \(record)")
            sale = Sale.newObjectWithMoc(moc)
            sale.isQuote = true
            sale.hidden = true
            sale.updateFromCloudRecord(record)
        }
        return sale
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> Sale? {
        let fetchRequest = NSFetchRequest(entityName: "Sale")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var customers = [AnyObject]()
        moc.performBlockAndWait() {
            customers = try! moc.executeFetchRequest(fetchRequest)
        }
        return customers.first as! Sale?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudSale" else {
            assertionFailure("sale cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.actualCharge = record["actualCharge"] as? NSNumber
            self.nominalCharge = record["nominalCharge"] as? NSNumber
            self.discountAmount = record["discountAmount"] as? NSNumber
            self.discountType = record["discountType"] as? NSNumber
            self.discountValue = record["discountValue"] as? NSNumber
            self.discountVersion = record["discountVersion"] as? NSNumber
            self.hidden = record["hidden"] as? NSNumber
            self.isQuote = record["isQuote"] as? NSNumber
            self.voided = record["voided"] as? NSNumber
        }
    }
}
extension SaleItem {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> SaleItem {
        var saleItem: SaleItem!
        moc.performBlockAndWait() {
            precondition(record.recordType == "icloudSaleItem", "Unable to create a SaleItem from this record \(record)")
            saleItem = SaleItem.newObjectWithMoc(moc)
            saleItem.updateFromCloudRecord(record)
        }
        return saleItem
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> SaleItem? {
        let fetchRequest = NSFetchRequest(entityName: "SaleItem")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var saleItems = [AnyObject]()
        moc.performBlockAndWait() {
            saleItems = try! moc.executeFetchRequest(fetchRequest)
        }
        return saleItems.first as! SaleItem?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudSaleItem" else {
            assertionFailure("saleItem cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.actualCharge = record["actualCharge"] as? NSNumber
            self.nominalCharge = record["nominalCharge"] as? NSNumber
            self.discountType = record["discountType"] as? NSNumber
            self.discountValue = record["discountValue"] as? NSNumber
            self.discountVersion = record["discountVersion"] as? NSNumber
            self.maximumCharge = record["maximumCharge"] as? NSNumber
            self.minimumCharge = record["minimumCharge"] as? NSNumber
            self.nominalCharge = record["nominalCharge"] as? NSNumber
        }
    }
}

extension Salon {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Salon {
        var salon: Salon!
        moc.performBlockAndWait() {
            precondition(record.recordType == "iCloudSalon", "Unable to create a salon from this record \(record)")
            salon = Salon(moc: moc)
            salon.updateFromCloudRecord(record)
        }
        return salon
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> Salon? {
        let fetchRequest = NSFetchRequest(entityName: "Salon")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var salons = [AnyObject]()
        moc.performBlockAndWait() {
            salons = try! moc.executeFetchRequest(fetchRequest)
        }
        return salons.first as! Salon?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "iCloudSalon" else {
            assertionFailure("Salon cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.salonName = record["name"] as? String
            self.postcode = record["postcode"] as? String
            self.phone = record["phone"] as? String
            self.addressLine1 = record["addressLine1"] as? String
            self.addressLine2 = record["addressLine2"] as? String
        }
    }
}

extension Customer {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Customer {
        var customer: Customer!
        moc.performBlockAndWait() {
            precondition(record.recordType == "icloudCustomer", "Unable to create a customer from this record \(record)")
            customer = Customer.newObjectWithMoc(moc)
            customer.updateFromCloudRecord(record)
        }
        return customer
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> Customer? {
        let fetchRequest = NSFetchRequest(entityName: "Customer")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var customers = [AnyObject]()
        moc.performBlockAndWait() {
            customers = try! moc.executeFetchRequest(fetchRequest)
        }
        return customers.first as! Customer?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudCustomer" else {
            assertionFailure("customer cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.firstName = record["firstName"] as? String
            self.lastName = record["lastName"] as? String
            self.phone = record["phone"] as? String
        }
    }
}
extension ServiceCategory {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> ServiceCategory {
        var serviceCategory: ServiceCategory!
        moc.performBlockAndWait() {
            precondition(record.recordType == "iCloudServiceCategory", "Unable to create a Service Category from this record \(record)")
            serviceCategory = ServiceCategory.newObjectWithMoc(moc)
            serviceCategory.updateFromCloudRecord(record)
        }
        return serviceCategory
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> ServiceCategory? {
        let fetchRequest = NSFetchRequest(entityName: "ServiceCategory")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var serviceCategories = [AnyObject]()
        moc.performBlockAndWait() {
            serviceCategories = try! moc.executeFetchRequest(fetchRequest)
        }
        return serviceCategories.first as! ServiceCategory?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudServiceCategory" else {
            assertionFailure("Service Category cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.name = record["name"] as? String
        }
    }
}
extension Service {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Service {
        var service: Service!
        moc.performBlockAndWait() {
            precondition(record.recordType == "iCloudService", "Unable to create a Service from this record \(record)")
            service = Service.newObjectWithMoc(moc)
            service.updateFromCloudRecord(record)
        }
        return service
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> Service? {
        let fetchRequest = NSFetchRequest(entityName: "Service")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var services = [AnyObject]()
        moc.performBlockAndWait() {
            services = try! moc.executeFetchRequest(fetchRequest)
        }
        return services.first as! Service?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "iCloudService" else {
            assertionFailure("Service cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.name = record["name"] as? String
            self.maximumCharge = record["maxPrice"] as? NSNumber
            self.minimumCharge = record["minPrice"] as? NSNumber
            self.nominalCharge = record["nominalPrice"] as? NSNumber
        }
    }
}
extension Employee {
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Employee {
        var employee: Employee!
        moc.performBlockAndWait() {
            precondition(record.recordType == "icloudEmployee", "Unable to create an Employee from this record \(record)")
            employee = Employee.newObjectWithMoc(moc)
            employee.updateFromCloudRecord(record)
        }
        return employee
    }
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext ) -> Employee? {
        let fetchRequest = NSFetchRequest(entityName: "Employee")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var employees = [AnyObject]()
        moc.performBlockAndWait() {
            employees = try! moc.executeFetchRequest(fetchRequest)
        }
        return employees.first as! Employee?
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudEmployee" else {
            assertionFailure("Employee cannot be updated from recordType \(record.recordType)")
            return
        }
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.firstName = record["firstName"] as? String
            self.lastName = record["lastName"] as? String
            self.phone = record["phone"] as? String
            self.email = record["email"] as? String
        }
    }
}

extension Appointment {
    class func fetchForCloudID(cloudID:String, moc:NSManagedObjectContext) -> Appointment? {
        let fetchRequest = NSFetchRequest(entityName: "Appointment")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var appointments = [AnyObject]()
        moc.performBlockAndWait() {
            appointments = try! moc.executeFetchRequest(fetchRequest)
        }
        return appointments.first as! Appointment?
    }
    class func makeFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Appointment {
        var appointment:Appointment!
        moc.performBlockAndWait { () -> Void in
            precondition(record.recordType == "icloudAppointment", "Unable to create an appointment from this record \(record)")
            appointment = Appointment.newObjectWithMoc(moc)
            appointment.updateFromCloudRecord(record)
        }
        return appointment
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudAppointment" else {
            assertionFailure("appointment cannot be updated from recordType \(record.recordType)")
            return
        }
        let startDate = record["appointmentStartDate"] as! NSDate
        let endDate = record["appointmentEndDate"] as! NSDate
        let bookedDuration = endDate.timeIntervalSinceDate(startDate)
        self.managedObjectContext?.performBlockAndWait() {
            self.setBQDataFromRecord(record)
            self.bqNeedsCoreDataExport = NSNumber(bool: false)
            self.appointmentDate = startDate
            self.bookedDuration = bookedDuration
        }
    }
}


