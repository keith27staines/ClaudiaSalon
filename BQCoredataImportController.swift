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
    
    let salonCloudID = "2C9BE77C-3809-45C0-BD72-80F615AD569B"
    let publicDatabase: CKDatabase
    let coredata = Coredata.sharedInstance
    let parentSalonRecordID:CKRecordID
    let parentSalonReference:CKReference
    var finished = false
    private let counter = AMCThreadSafeCounter(name: "coredataImporter", initialValue: 0)
    
    init() {
        parentSalonRecordID = CKRecordID(recordName: salonCloudID)
        parentSalonReference = CKReference(recordID: parentSalonRecordID, action: .None)
        let container = CKContainer(identifier: "iCloud.uk.co.ClaudiasSalon.ClaudiaSalon")
        publicDatabase = container.publicCloudDatabase
        self.deleteAllCoredataAppointments()
    }
    func deleteAllCoredataAppointments() {
        let fetchRequest = NSFetchRequest(entityName: "Appointment")
        let yesPredicate = NSPredicate(value: true)
        fetchRequest.predicate = yesPredicate
        let moc = self.coredata.backgroundContext
        moc.performBlockAndWait() {
            let fetchedObjects = try! moc.executeFetchRequest(fetchRequest)
            for modelObject in fetchedObjects {
                moc.deleteObject(modelObject as! NSManagedObject)
            }
            self.coredata.saveContext()
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
                try! moc.save()
            }
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
        super.recordFetchedBlock = { record in
            self.moc.performBlockAndWait() {
                if let saleItem = SaleItem.fetchForCloudID(record.recordID.recordName, moc: self.moc) {
                    saleItem.updateFromCloudRecordIfNeeded(record)
                    self.synchQueue.addOperationWithBlock() { self.saleItemsFromCloud.insert(saleItem) }
                } else {
                    let saleItem = SaleItem.makeFromCloudRecord(record, moc: self.moc)
                    self.synchQueue.addOperationWithBlock() { self.saleItemsFromCloud.insert(saleItem) }
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
                self.sale.removeSaleItem(currentItems)
                self.sale.addSaleItem(self.saleItemsFromCloud)
                let removedSet = currentItems.subtract(self.saleItemsFromCloud)
                for removed in removedSet {
                    self.moc.deleteObject(removed)
                }
                try! self.moc.save()
            }
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
            let moc = Coredata.sharedInstance.backgroundContext
            try! moc.save()
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
        if cloudRecord.modificationDate!.isGreaterThan(self.lastUpdatedDate!) {
            return true
        }
        return false  // We don't need to update ourself as we are more recent
    }
    func updateFromCloudRecordIfNeeded(record:CKRecord) {
        if self.doesNeedUpdateFromCloud(record) {
            self.updateFromCloudRecord(record)
        }
    }
    func updateFromCloudRecord(record:CKRecord) {
        fatalError("Subclasses must override this")
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
        var customers = [AnyObject]()
        moc.performBlockAndWait() {
            customers = try! moc.executeFetchRequest(fetchRequest)
        }
        return customers.first as! SaleItem?
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


