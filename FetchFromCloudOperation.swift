//
//  FetchFromCloudOperation.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 30/04/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

struct DeletionInfo {
    var state = DeleteOperationStates.Waiting
    var recordTypeInformation = [ICloudRecordType:RecordTypeInfo]()
}

struct RecordTypeInfo {
    var status = RecordTypeInfoStates.Waiting
    var recordType:ICloudRecordType = ICloudRecordType.Salon
    var records = [CKRecord]()
    var error:NSError? = nil
}

enum RecordTypeInfoStates: String {
    case Waiting = "waiting"
    case FetchingIDs = "fetching"
    case FetchIDsComplete = "fetched complete"
    case ErrorFetchingIDs = "error fetching"
    case DeletingRecords = "deleting"
    case DeletingRecordsComplete = "delete complete"
    case ErrorDeletingRecords = "error deleting records"
    case Cancelled = "cancelled"
}

enum DeleteOperationStates: String {
    case Waiting = "waiting"
    case FetchingIDs = "fetching"
    case FetchFinished = "fetch finished"
    case DeletingRecords = "deleting"
    case SuccessfulDeletion = "success"
    case FailedDeletion = "failed"
    case Cancelled = "cancelled"
}

class FetchFromCloudOperation : NSOperation {
    
    private var deletionInfo = DeletionInfo()
    private let containerID:String
    private let salonRecordName:String
    private let completionResult:(DeletionInfo)->Void
    private let cloudDatabase:CKDatabase
    private var operations = [NSOperation]()

    private let synchQueue:NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "FetchFromCloud"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    init(containerID:String, salonRecordName:String, completionResult:(DeletionInfo)->Void) {
        self.containerID = containerID
        let container = CKContainer(identifier: containerID)
        self.cloudDatabase = container.publicCloudDatabase
        self.salonRecordName = salonRecordName
        self.completionResult = completionResult
        super.init()
        self.setupInformation()
    }
    
    func setupInformation() {
        self.deletionInfo.state = .Waiting
        self.deletionInfo.recordTypeInformation[ICloudRecordType.Salon] = RecordTypeInfo(status: .Waiting, recordType: ICloudRecordType.Salon, records: [CKRecord](), error:nil)
        self.deletionInfo.recordTypeInformation[ICloudRecordType.Employee] = RecordTypeInfo(status: .Waiting, recordType: ICloudRecordType.Employee, records: [CKRecord](), error:nil)
        self.deletionInfo.recordTypeInformation[ICloudRecordType.Customer] = RecordTypeInfo(status: .Waiting, recordType: ICloudRecordType.Customer, records: [CKRecord](), error:nil)
        self.deletionInfo.recordTypeInformation[ICloudRecordType.ServiceCategory] = RecordTypeInfo(status: .Waiting, recordType: ICloudRecordType.ServiceCategory, records: [CKRecord](), error:nil)
        self.deletionInfo.recordTypeInformation[ICloudRecordType.Service] = RecordTypeInfo(status: .Waiting, recordType: ICloudRecordType.Service, records: [CKRecord](), error:nil)
        self.deletionInfo.recordTypeInformation[ICloudRecordType.Appointment] = RecordTypeInfo(status: .Waiting, recordType: ICloudRecordType.Appointment, records: [CKRecord](), error:nil)
        self.deletionInfo.recordTypeInformation[ICloudRecordType.Sale] = RecordTypeInfo(status: .Waiting, recordType: ICloudRecordType.Sale, records: [CKRecord](), error:nil)
        self.deletionInfo.recordTypeInformation[ICloudRecordType.SaleItem] = RecordTypeInfo(status: .Waiting, recordType: ICloudRecordType.SaleItem, records: [CKRecord](), error:nil)
    }
    
    override func main() {
        if self.cancelled { return }
    
        for (_,recordInfo) in self.deletionInfo.recordTypeInformation {
            let queryOperation = self.fetchIDOperationForRecordType(recordInfo.recordType)
            self.cloudDatabase.addOperation(queryOperation)
        }
    }
    
    func recordIDFetchWasCompleted(recordType:ICloudRecordType) {
        var allComplete = true
        var error = false
        for (_,recordInfo) in self.deletionInfo.recordTypeInformation {
            if recordInfo.status != .FetchIDsComplete {
                allComplete = false
            }
            if recordInfo.status == .ErrorFetchingIDs {
                error = true
            }
        }
        if error {
            self.deletionInfo.state = .FailedDeletion
        } else if allComplete {
            self.deletionInfo.state = .FetchFinished
        } else {
            self.deletionInfo.state = .FetchingIDs
        }
        self.completionResult(self.deletionInfo)
    }
    
    
    func addFetchedRecordIDToTableInformation(fetchedRecord:CKRecord) {
        let recordType = ICloudRecordType(rawValue:fetchedRecord.recordType)!
        self.deletionInfo.recordTypeInformation[recordType]?.records.append(fetchedRecord)
    }
}

extension FetchFromCloudOperation {
    func fetchIDOperationForRecordType(recordType:ICloudRecordType) -> CKQueryOperation {
        var predicate : NSPredicate!
        let salonRecordID = CKRecordID(recordName: self.salonRecordName)
        let salonReference = CKReference(recordID: salonRecordID, action: .None)
        if recordType == ICloudRecordType.Salon {
            predicate = NSPredicate(format: "recordID = %@", salonRecordID)
        } else {
            predicate = NSPredicate(format: "parentSalonReference = %@", salonReference)
        }
        let query = CKQuery(recordType: recordType.rawValue, predicate: predicate)
        let queryOp = CKQueryOperation(query: query)
        queryOp.desiredKeys = ["parentSalonReference"]
        queryOp.queuePriority = .VeryHigh
        
        queryOp.queryCompletionBlock = { cursor, error in
            self.processCompletedRecordFetch(queryOp,cursor: cursor, error: error)
        }
        
        queryOp.recordFetchedBlock = { record in
            self.processFetchedRecord(record)
        }
        return queryOp
    }

    private func processCompletedRecordFetch(queryOp:CKQueryOperation, cursor:CKQueryCursor?, error:NSError?) {
        guard let recordType = ICloudRecordType(rawValue: queryOp.query!.recordType) else {
            preconditionFailure("Unexpected record type")
        }
        if let cursor = cursor {
            self.synchQueue.addOperationWithBlock() {
                self.deletionInfo.recordTypeInformation[recordType]!.status = RecordTypeInfoStates.FetchingIDs
            }
            let continuationOperation = CKQueryOperation(cursor: cursor)
            continuationOperation.recordFetchedBlock = self.processFetchedRecord
            continuationOperation.queryCompletionBlock = { cursor, error in
                self.processCompletedRecordFetch(queryOp,cursor: cursor, error: error)
            }
            self.cloudDatabase.addOperation(continuationOperation)
            return
        }
        
        self.synchQueue.addOperationWithBlock() {
            if error != nil {
                self.deletionInfo.recordTypeInformation[recordType]!.error = error
                self.deletionInfo.recordTypeInformation[recordType]!.status = RecordTypeInfoStates.ErrorFetchingIDs
            } else {
                self.deletionInfo.recordTypeInformation[recordType]!.status = RecordTypeInfoStates.FetchIDsComplete
            }
            self.recordIDFetchWasCompleted(recordType)
        }
    }
    private func processFetchedRecord(record:CKRecord) {
        self.synchQueue.addOperationWithBlock() {
            if let salonReference = record["parentSalonReference"] as? CKReference {
                // Dealing with a child record of a salon
                let salonRecordName = salonReference.recordID.recordName
                if salonRecordName != self.salonRecordName {
                    print("Warning - record may belong to a different salon")
                }
            } else {
                // Dealing with Salon record
                if record.recordID.recordName != self.salonRecordName {
                    print("Warning - record may belong to a different salon")
                }
            }
            self.addFetchedRecordIDToTableInformation(record)
        }
    }

}