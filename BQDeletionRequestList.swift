//
//  BQDeletionRequestList.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 04/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

// MARK:- Class BQDeletionRequestList
class BQDeletionRequestList {
    var requestListDictionary:[String:BQExportDeletionRequest]
    let managedObjectContext:NSManagedObjectContext
    var deleteOperation: CKModifyRecordsOperation!
    lazy var publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    var activeOperations = 0
    
    init(managedObjectContext:NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.requestListDictionary = [String:BQExportDeletionRequest]()
        self.deleteOperation = self.makeDeleteOperation()
        self.loadRequestListDictionary()
    }
    
    // MARK:- Process the list
    func processList() {
        if self.activeOperations > 0 {
            return
        }
        self.activeOperations++
        self.deleteOperation.recordIDsToDelete = nil
        var recordIDsToDelete = [CKRecordID]()
        for (_,deletionRequest) in self.requestListDictionary {
            let recordID = deletionRequest.cloudkitRecordFromEmbeddedMetadata()!.recordID
            recordIDsToDelete.append(recordID)
        }
        self.deleteOperation.recordIDsToDelete = recordIDsToDelete
        self.publicDatabase.addOperation(self.deleteOperation)
    }
    // MARK:- Delete recordIDs from cloud
    private func makeDeleteOperation() -> CKModifyRecordsOperation {
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: nil)
        operation.completionBlock = {
            dispatch_sync(dispatch_get_main_queue(), {self.activeOperations--})
        }
        operation.modifyRecordsCompletionBlock = { (_,recordIDsToDelete,error)->Void in
            guard let recordIDsToDelete = recordIDsToDelete else {
                return
            }
            let attemptedDeletions = Set(recordIDsToDelete)
            var failedDeletions = Set<CKRecordID>()
            var failedDeletionsDictionary: [CKRecordID:NSError]?
            if let error = error {
                switch error {
                case CKErrorCode.LimitExceeded.rawValue:
                    // Need to recurse down to smaller operation
                    // Remember to increment activeOperationCount like so...
                    // dispatch_sync(dispatch_get_main_queue(), {self.activeOperations++})
                    // for each spawned operation
                    assertionFailure("Need to recurse down to smaller operation")
                    break
                case error.code == CKErrorCode.PartialFailure.rawValue:
                    failedDeletionsDictionary = error.userInfo[CKPartialErrorsByItemIDKey] as! [CKRecordID:NSError]?
                    failedDeletions = Set(failedDeletionsDictionary!.keys)
                case error.userInfo["CKErrorRetryAfterKey"] != nil:
                    // Transient failure - can retry this operation after a suitable delay
                    let retryAfter = error.userInfo["CKErrorRetryAfterKey"]!.doubleValue
                    self.retryOperation(operation, waitInterval: retryAfter)
                default:
                    // Operation failed unrecoverably so nothing we can do except maybe figure out why
                    assertionFailure("Operation failed unrecoverably so nothing we can do except maybe figure out why")
                    return
                }
            }
            // get the successes (successes = attempts - failures) and inform the deletion request list about the successes
            let successfullyDeleted = attemptedDeletions.subtract(failedDeletions)
            self.requestsSucceeded(successfullyDeleted)
            
            // Inform the deletion request list about any failures
            if let failedDeletionsDictionary = failedDeletionsDictionary {
                self.requestsFailed(failedDeletionsDictionary)
            }
        }
        return operation
    }
    
    // MARK:- Retry operation
    private func retryOperation(operation:CKModifyRecordsOperation, waitInterval:Double) {
        let waitIntervalNanoseconds = Int64(waitInterval * 1000_000_000.0)
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, waitIntervalNanoseconds)
        dispatch_after(dispatchTime, dispatch_get_main_queue()) { () -> Void in
            dispatch_sync(dispatch_get_main_queue(), {self.activeOperations++})
            self.publicDatabase.addOperation(operation)
        }
    }

    // MARK:- Add new  deletion requests
    func addCloudDeletionRequestsForLocallyDeletedObjects(deletedObjects:Set<NSManagedObject>) {
        for deletedObject in deletedObjects {
            self.addCloudDeletionRequestForLocallyDeletedObject(deletedObject)
        }
    }
    func addCloudDeletionRequestForLocallyDeletedObject(deletedObject:NSManagedObject) {
        if let metadata = deletedObject.bqdata?.metadata {
            self.addCloudDeletionRequestsForRecordWithMetadata(metadata)
        }
    }
    //MARK:- Notify successes and failures
    func requestsSucceeded(successfullyDeleted:Set<CKRecordID>) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            for recordID in successfullyDeleted {
                let recordName = recordID.recordName
                if let request = self.requestListDictionary[recordName] {
                    request.deletionSucceeded()
                }
                self.requestListDictionary[recordName] = nil
            }
        }
    }
    func requestsFailed(failed:[CKRecordID:NSError]) {
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            for (recordID,error) in failed {
                let recordName = recordID.recordName
                if let request = self.requestListDictionary[recordName] {
                    request.failWithError(error)
                }
            }
        }
    }
    // MARK:- Fetching deletion requests
    func fetchAllRequests() -> Set<BQExportDeletionRequest> {
        let fetchRequest = NSFetchRequest(entityName: "BQExportDeletionRequest")
        do {
            let fetchResults = (try managedObjectContext.executeFetchRequest(fetchRequest)) as! [BQExportDeletionRequest]
            return Set(fetchResults)
        } catch {
            return Set<BQExportDeletionRequest>()
        }
    }
    func fetchAllPendingRequests() -> Set<BQExportDeletionRequest> {
        let pendingRequests = self.fetchAllRequests().filter({ (request) -> Bool in
            if request.actionResult == "Pending" || request.actionResult == "Retry" {
                return true
            } else {
                return false
            }
        })
        return Set(pendingRequests)
    }
    func fetchAllFailedRequests() -> Set<BQExportDeletionRequest> {
        let failedRequests = self.fetchAllRequests().filter { $0.lastErrorCode != nil }
        return Set(failedRequests)
    }
    
    // MARK:- Private helper functions
    private func addCloudDeletionRequestsForRecordWithMetadata(metadata:NSData) -> BQExportDeletionRequest {
        let request = NSEntityDescription.insertNewObjectForEntityForName("BQExportDeletionRequest", inManagedObjectContext: managedObjectContext) as! BQExportDeletionRequest
        let record = NSManagedObject.cloudkitRecordFromMetadata(metadata)
        request.cloudRecordName = record!.recordID.recordName
        request.managedObjectDeletionDate = NSDate()
        request.bqMetadata = metadata
        request.actionResult = "Pending"
        self.requestListDictionary[request.cloudRecordName!] = request
        return request
    }

    private func loadRequestListDictionary() {
        self.requestListDictionary.removeAll()
        let allRequests = self.fetchAllRequests()
        for request in allRequests {
            self.requestListDictionary[request.cloudRecordName!] = request
        }
    }
}
