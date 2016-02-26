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
    
    let salonCloudID = "A845885F-958A-4CE3-A729-42F08EA9238F"
    let publicDatabase: CKDatabase
    let coredata = Coredata.sharedInstance
    let parentSalonRecordID:CKRecordID
    let parentSalonReference:CKReference
    
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
        let fetchedObjects = try! self.coredata.managedObjectContext.executeFetchRequest(fetchRequest)
        for mo in fetchedObjects {
            self.coredata.managedObjectContext.deleteObject(mo as! NSManagedObject)
        }
        self.coredata.saveContext()
    }
    
    func fetchCloudAppointments() {
        let queryOperation = self.queryOperationForAppointments()
        publicDatabase.addOperation(queryOperation)
    }
    func queryOperationForAppointments()->CKQueryOperation {
        let earliestDate = NSDate().dateByAddingTimeInterval(-30*24*3600);
        let predicate = NSPredicate(format: "appointmentStartDate >= %@ AND parentSalonReference = %@", earliestDate,self.parentSalonReference)
        let query = CKQuery(recordType: "icloudAppointment", predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.resultsLimit = 1
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
                self.publicDatabase.addOperation(nextBatch)
            }
        }
        return queryOperation
    }
    func processDownloadedAppointment(appointmentRecord:CKRecord) {
        let cloudID = appointmentRecord.recordID.recordName
        let moc = coredata.backgroundContext
        coredata.managedObjectContext.performBlock() {
            var appointment = Appointment.fetchAppointmentForCloudID(cloudID, moc: moc)
            if let appointment = appointment {
                appointment.updateFromCloudRecord(appointmentRecord)
            } else {
                appointment = Appointment.makeAppointmentFromCloudRecord(appointmentRecord, moc: moc)
            }
            self.coredata.saveContext()
        }
    }
}
extension Appointment {
    class func fetchAppointmentForCloudID(cloudID:String, moc:NSManagedObjectContext) -> Appointment? {
        let fetchRequest = NSFetchRequest(entityName: "Appointment")
        let predicate = NSPredicate(format: "bqCloudID = %@", cloudID)
        fetchRequest.predicate = predicate
        let appointments = try! moc.executeFetchRequest(fetchRequest)
        return appointments.first as! Appointment?
    }
    class func makeAppointmentFromCloudRecord(record:CKRecord, moc:NSManagedObjectContext) -> Appointment {
        precondition(record.recordType == "icloudAppointment", "Unable to create an appointment from this record \(record)")
        let appointment = Appointment.newObjectWithMoc(moc)
        appointment.bqCloudID = record.recordID.recordName
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWithMutableData: data)
        record.encodeSystemFieldsWithCoder(coder)
        coder.finishEncoding()
        appointment.bqMetadata = data
        appointment.bqNeedsCoreDataExport = record["needsExportToCoredata"] as! Bool
        appointment.appointmentDate = record["appointmentStartDate"] as? NSDate!
        appointment.appointmentEndDate = record["appointmentEndDate"] as? NSDate!
        return appointment
    }
    func updateFromCloudRecord(record:CKRecord) {
        guard record.recordType == "icloudAppointment" else {
            assertionFailure("appointment cannot be updated from recordtype \(record.recordType)")
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


