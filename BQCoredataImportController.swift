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
        //self.deleteAllCoredataAppointments()
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
            var appointment = Appointment.fetchAppointmentForCloudID(cloudID, moc: moc)
            if let appointment = appointment {
                appointment.updateFromCloudRecordIfNeeded(appointmentRecord)
            } else {
                appointment = Appointment.makeAppointmentFromCloudRecord(appointmentRecord, moc: moc)
            }
            self.filloutAppointment(appointment!,appointmentRecord: appointmentRecord,moc: moc)
        }
    }
}

extension BQCoredataImportController {
    func filloutAppointment(appointment:Appointment, appointmentRecord:CKRecord, moc:NSManagedObjectContext) {
        let customerRef = appointmentRecord["parentCustomerReference"] as! CKReference
        let customerID = customerRef.recordID
        self.counter.increment()
        self.publicDatabase.fetchRecordWithID(customerID) { customerRecord, error in
            moc.performBlockAndWait() {
                if error != nil {
                    print("Unresolved error fetching customer from cloud \(error)")
                } else {
                    appointment.customer = Customer.makeCustomerFromCloudRecord(customerRecord!,moc: moc)
                }
                try! moc.save()
            }
            self.counter.decrement()
        }
    }
}

extension Customer {
    class func makeCustomerFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Customer {
        var customer: Customer!
        moc.performBlockAndWait() {
            precondition(record.recordType == "icloudCustomer", "Unable to create a customer from this record \(record)")
            customer = Customer.newObjectWithMoc(moc)
            customer.bqCloudID = record.recordID.recordName
            let data = NSMutableData()
            let coder = NSKeyedArchiver(forWritingWithMutableData: data)
            record.encodeSystemFieldsWithCoder(coder)
            coder.finishEncoding()
            customer.bqMetadata = data
            customer.bqNeedsCoreDataExport = record["needsExportToCoredata"] as! Bool
            customer.firstName = record["firstName"] as? String
            customer.lastName = record["lastName"] as? String
            customer.phone = record["phone"] as? String
        }
        return customer
    }
}

extension Appointment {
    class func fetchAppointmentForCloudID(cloudID:String, moc:NSManagedObjectContext) -> Appointment? {
        let fetchRequest = NSFetchRequest(entityName: "Appointment")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        var appointments = [AnyObject]()
        moc.performBlockAndWait() {
            appointments = try! moc.executeFetchRequest(fetchRequest)
        }
        return appointments.first as! Appointment?
    }
    class func makeAppointmentFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Appointment {
        var appointment:Appointment!
        moc.performBlockAndWait { () -> Void in
            precondition(record.recordType == "icloudAppointment", "Unable to create an appointment from this record \(record)")
            appointment = Appointment.newObjectWithMoc(moc)
            appointment.bqCloudID = record.recordID.recordName
            let data = NSMutableData()
            let coder = NSKeyedArchiver(forWritingWithMutableData: data)
            record.encodeSystemFieldsWithCoder(coder)
            coder.finishEncoding()
            appointment.bqMetadata = data
            appointment.bqNeedsCoreDataExport = record["needsExportToCoredata"] as! Bool
            let startDate = record["appointmentStartDate"] as! NSDate
            let endDate = record["appointmentEndDate"] as! NSDate
            let bookedDuration = endDate.timeIntervalSinceDate(startDate)
            appointment.appointmentDate = startDate
            appointment.bookedDuration = bookedDuration
        }
        return appointment
    }
    func updateFromCloudRecordIfNeeded(record:CKRecord) {
        guard self.doesNeedUpdateFromCloud(record) else {
            return
        }
        self.updateFromCloudRecord(record)
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudAppointment" else {
            assertionFailure("appointment cannot be updated from recordType \(record.recordType)")
            return
        }
        if let startDate = record["appointmentStartDate"] as? NSDate {
            self.appointmentDate = startDate
        }
        if let endDate = record["appointmentEndDate"] as? NSDate {
            self.appointmentEndDate = endDate
        }
    }
    func doesNeedUpdateFromCloud(record:CKRecord) -> Bool {
        precondition(record.recordType == "icloudAppointment", "Cloud record \(record.recordType) doesn't match icloudAppointment")
        guard let metadata = self.bqMetadata else {
            return true // We have never been initialised with any data from the cloud
        }
        let decoder = NSKeyedUnarchiver(forReadingWithData: metadata)
        guard let _ = CKRecord(coder: decoder) else {
            preconditionFailure("Unable to decode the cloud record from the supplied metadata")
        }
        if record.modificationDate!.isGreaterThan(self.lastUpdatedDate!) {
            return true
        }
        return false  // We don't need to update ourself as we are more recent
    }
}


