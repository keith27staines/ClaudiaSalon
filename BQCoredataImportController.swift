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
    
    let salonCloudID = "8DD47585-0947-446E-A5DC-DD95DD23C763"
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
        //let saleOperation = SaleForAppointmentOperation(appointment: appointment, appointmentRecord: appointmentRecord)
        //let saleItemsOperation = SaleItemsForSaleOperation()
        //saleItemsOperation.addDependency(saleOperation)
        //saleOperation.addDependency(customerOperation)
        //return [customerOperation,saleOperation,saleItemsOperation]
        return [customerOperation]
    }
}

class SaleItemsForSaleOperation: NSOperation {
    private (set) var saleItems = [SaleItem]()
    
}
//class SaleForAppointmentOperation: NSOperation {
//    var error: NSError?
//    let appointment:Appointment
//    let appointmentRecord:CKRecord
//    private (set) var customerRecord: CKRecord?
//    private (set) var customer: Customer?
//    
//    var appointmentRecord: CKRecord? {
//        willSet {
//            self.willChangeValueForKey("ready")
//        }
//        didSet {
//            let predicate = NSPredicate(format: "recordID == %@", appointmentRecord!.recordID)
//            self.query = CKQuery(recordType: "icloudCustomer", predicate: predicate)
//            self.didChangeValueForKey("ready")
//        }
//    }
//    
//    override var ready: Bool {
//        return super.ready && self.appointmentRecord != nil
//    }
//    
//    init(appointment:Appointment,appointmentRecord:CKRecord) {
//        super.init()
//        super.recordFetchedBlock = { record in
//            self.customerRecord = record
//        }
//        self.queryCompletionBlock  = { (queryCursor, error) in
//            guard error == nil else {
//                self.error = error
//                assertionFailure("error while fetching appointment's customer \(error)")
//                return
//            }
//        }
//    }
//}

protocol AppointmentBuilder {
    var error: NSError? { get }
    var appointment: Appointment? { get }
}

class CustomerForAppointmentOperation : CKQueryOperation, AppointmentBuilder {
    var error: NSError?
    private (set) var appointment:Appointment?
    private (set) var appointmentRecord:CKRecord
    private (set) var customerRecord: CKRecord?
    private (set) var customer: Customer?
    
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
    var publicDatabase: CKDatabase = { CKContainer(identifier: "iCloud.uk.co.ClaudiasSalon.ClaudiaSalon").publicCloudDatabase }()
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


