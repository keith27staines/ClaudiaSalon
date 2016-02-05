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
    
    init(managedObjectContext:NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        self.requestListDictionary = [String:BQExportDeletionRequest]()
        self.loadRequestListDictionary()
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
