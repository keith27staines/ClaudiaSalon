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
    let maxRecordsToDeleteInBatch = 200
    private let privateDispatchQueue = dispatch_queue_create("com.AMCAldebaron.BQDeletionRequestList", DISPATCH_QUEUE_SERIAL)

    var requestListDictionary:[String:BQExportDeletionRequest]
    let parentManagedObjectContext: NSManagedObjectContext
    var deleteOperations = Set<CKModifyRecordsOperation>()
    lazy var publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    let activeOperationCounter = AMCThreadSafeCounter(initialValue: 0)
    var privateManagedObjectContext:NSManagedObjectContext!
    
    // MARK:- Initialiser and deinit
    init(parentManagedObjectContext:NSManagedObjectContext) {
        self.parentManagedObjectContext = parentManagedObjectContext
        self.requestListDictionary = [String:BQExportDeletionRequest]()
        dispatch_sync(self.privateDispatchQueue) {
            self.privateManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            self.privateManagedObjectContext.parentContext = self.parentManagedObjectContext
        }
        self.loadRequestListDictionary()
        
        // Monitor new deletions from coredata
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: self.parentManagedObjectContext, queue: NSOperationQueue.mainQueue()) { notification in
            // Managed objects just-deleted from the parent managed object (these changed being driven by user interaction) must be added to a deletion list for later removal from icloud
            if let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] {
                let deletedManagedObjects = deletedObjects as! Set<NSManagedObject>
                self.addCloudDeletionRequestsForLocallyDeletedObjects(deletedManagedObjects)
            }
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK:- Start and stop processing
    
    /** processList() starts the processing of the items recorded in the coredata deletionRequest entity. The objects are examined for bqMetadata and if found, the corresponding object in iCloud is deleted. Finally, the deletion request is deleted */
    func processList() {
        dispatch_sync(self.privateDispatchQueue) {
            if self.activeOperationCounter.count > 0 {
                return
            }
            self.activeOperationCounter.increment()
            var recordIDsToDelete = [CKRecordID]()
            for (_,deletionRequest) in self.requestListDictionary {
                let recordID = deletionRequest.cloudkitRecordFromEmbeddedMetadata()!.recordID
                recordIDsToDelete.append(recordID)
                if recordIDsToDelete.count > self.maxRecordsToDeleteInBatch {
                    // We don't want to lock up the interface if there are huge numbers of records to delete
                    break
                }
            }
            let deleteOperation = self.makeDeleteOperation(recordIDsToDelete)
            self.publicDatabase.addOperation(deleteOperation)
        }
    }
    
    func cancel() {
        dispatch_sync(self.privateDispatchQueue) {
            for operation in self.deleteOperations {
                if operation.executing || operation.ready {
                    operation.cancel()
                }
            }
        }
    }
    
    // MARK:- Delete recordIDs from cloud
    private func makeDeleteOperation(recordIDsToDelete:[CKRecordID]) -> CKModifyRecordsOperation {

        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsToDelete)
        
        operation.completionBlock = {
            self.activeOperationCounter.decrement()
            dispatch_sync(self.privateDispatchQueue) {self.deleteOperations.remove(operation)}
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
                    /* This operation was "too big", so recurse down to 
                       ever smaller operations until they succeed or 
                       fail for a different reason
                    */
                    
                    // Divide the recordIDs array into two halves
                    let n = recordIDsToDelete.count / 2
                    var firstHalfRecords = [CKRecordID]()
                    var secondHalfRecords = [CKRecordID]()
                    for index in recordIDsToDelete.indices {
                        if index <= n {
                            firstHalfRecords.append(recordIDsToDelete[index])
                        } else {
                            secondHalfRecords.append(recordIDsToDelete[index])
                        }
                    }
                    // Spool new operations for first half
                    let firsHalfOperation = self.makeDeleteOperation(firstHalfRecords)
                    self.activeOperationCounter.increment()
                    self.publicDatabase.addOperation(firsHalfOperation)

                    // Spool new operation for second half
                    let secondHalfOperation = self.makeDeleteOperation(secondHalfRecords)
                    self.activeOperationCounter.increment()
                    self.publicDatabase.addOperation(secondHalfOperation)
                    return
                case error.code == CKErrorCode.PartialFailure.rawValue:
                    // Get into about the failed deletions, further processing is deferred...
                    failedDeletionsDictionary = error.userInfo[CKPartialErrorsByItemIDKey] as! [CKRecordID:NSError]?
                    failedDeletions = Set(failedDeletionsDictionary!.keys)
                case error.userInfo["CKErrorRetryAfterKey"] != nil:
                    // Transient failure - can retry this operation after a suitable delay. In our sense, this operation remains active during the wait and retry, so this is the only case where we don't change the activeOperation counter
                    let retryAfter = error.userInfo["CKErrorRetryAfterKey"]!.doubleValue
                    self.retryOperation(operation, waitInterval: retryAfter)
                    return
                default:
                    // Operation failed unrecoverably so nothing we can do except maybe figure out why
                    assertionFailure("Operation failed unrecoverably so nothing we can do unless we can figure out why")
                    return
                }
            }
            
            // If we get to here, we either completely succeeded or partially succeeded.
            
            // First we process the successes (successes = attempts - failures).
            let successfullyDeleted = attemptedDeletions.subtract(failedDeletions)
            self.requestsSucceeded(successfullyDeleted)
            
            // Now the failures...
            if let failedDeletionsDictionary = failedDeletionsDictionary {
                self.requestsFailed(failedDeletionsDictionary)
            }
        }
        dispatch_sync(self.privateDispatchQueue) {self.deleteOperations.insert(operation)}
        return operation
    }
    
    // MARK:- Retry operation
    private func retryOperation(operation:CKModifyRecordsOperation, waitInterval:Double) {
        let waitIntervalNanoseconds = Int64(waitInterval * 1000_000_000.0)
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, waitIntervalNanoseconds)
        dispatch_after(dispatchTime, self.privateDispatchQueue) { () -> Void in
            self.activeOperationCounter.increment()
            self.publicDatabase.addOperation(operation)
        }
    }

    // MARK:- Add new  deletion requests
    func addCloudDeletionRequestsForLocallyDeletedObjects(deletedObjects:Set<NSManagedObject>) {
        for deletedObject in deletedObjects {
            // Skip deleted deletionRequests to avoid horrible unwanted recursion
            if deletedObject.isKindOfClass(BQExportDeletionRequest) { continue }
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
        dispatch_sync(self.privateDispatchQueue) {
            for recordID in successfullyDeleted {
                let recordName = recordID.recordName
                if let request = self.requestListDictionary[recordName] {
                    self.privateManagedObjectContext.performBlockAndWait() {
                        self.privateManagedObjectContext.deleteObject(request)
                    }
                }
                self.requestListDictionary[recordName] = nil
            }
            self.privateManagedObjectContext.performBlockAndWait() {
                do {
                    try self.privateManagedObjectContext.save()
                } catch {
                    // What to do now?
                }
            }
        }
    }
    func requestsFailed(failed:[CKRecordID:NSError]) {
        dispatch_async(self.privateDispatchQueue) {
            for (recordID,error) in failed {
                let recordName = recordID.recordName
                if let request = self.requestListDictionary[recordName] {
                    request.failedWithError(error)
                }
            }
        }
    }
    
    // MARK:- Fetching deletion requests
    /** only call fetchAllRequests on the main thread */
    func fetchAllRequests() -> Set<BQExportDeletionRequest> {
        let fetchRequest = NSFetchRequest(entityName: "BQExportDeletionRequest")
        do {
            let fetchResults = (try self.parentManagedObjectContext.executeFetchRequest(fetchRequest)) as! [BQExportDeletionRequest]
            return Set(fetchResults)
        } catch {
            return Set<BQExportDeletionRequest>()
        }
    }
    /** Only call fetchAllPendingRequests on the main thread */
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
    /** Only call fetchAllPendingRequests on the main thread */
    func fetchAllFailedRequests() -> Set<BQExportDeletionRequest> {
        let failedRequests = self.fetchAllRequests().filter { $0.lastErrorCode != nil }
        return Set(failedRequests)
    }
    
    // MARK:- Private helper functions
    
    /** addCloudDeletionRequestsForRecordWithMetadata: must be called from the main thread */
    private func addCloudDeletionRequestsForRecordWithMetadata(metadata:NSData) -> BQExportDeletionRequest {
        let request = NSEntityDescription.insertNewObjectForEntityForName("BQExportDeletionRequest", inManagedObjectContext: self.parentManagedObjectContext) as! BQExportDeletionRequest
        let record = NSManagedObject.cloudkitRecordFromMetadata(metadata)
        request.cloudRecordName = record!.recordID.recordName
        request.managedObjectDeletionDate = NSDate()
        request.bqMetadata = metadata
        request.actionResult = "Pending"
        dispatch_sync(self.privateDispatchQueue) {
            self.requestListDictionary[request.cloudRecordName!] = request
        }
        return request
    }

    private func loadRequestListDictionary() {
        let moc = self.privateManagedObjectContext
        moc.performBlockAndWait() {
            self.requestListDictionary.removeAll()
            let fetchRequest = NSFetchRequest(entityName: "BQExportDeletionRequest")
            var allRequests: Set<BQExportDeletionRequest>
            do {
                let fetchResults = (try moc.executeFetchRequest(fetchRequest)) as! [BQExportDeletionRequest]
                allRequests = Set(fetchResults)
            } catch {
                allRequests = Set<BQExportDeletionRequest>()
            }
            for request in allRequests {
                self.requestListDictionary[request.cloudRecordName!] = request
            }
        }
    }
}
