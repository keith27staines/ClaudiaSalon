//
//  BQCoredataImportController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

class BQCoredataImportController {
    let salonCloudID = "F30B020F-D5BD-4DA8-BBBF-C2A6F76AB2CA"
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    
    func fetchCloudAppointments() {
        let queryOperation = self.queryOperationForAppointments()
        publicDatabase.addOperation(queryOperation)
    }
    func queryOperationForAppointments()->CKQueryOperation {
        let earliestDate = NSDate().dateByAddingTimeInterval(-30*24*3600);
        let predicate = NSPredicate(format: "appointmentStartDate >= %@", earliestDate)
        let query = CKQuery(recordType: "Appointment", predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.recordFetchedBlock = {  record in
            self.appointmentRecordDownloaded(record)
        }
        queryOperation.queryCompletionBlock = { (cursor, error) in
            if queryOperation.cancelled {
                return
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
    func appointmentRecordDownloaded(appointmentRecord:CKRecord) {
        
        
    }
    
}