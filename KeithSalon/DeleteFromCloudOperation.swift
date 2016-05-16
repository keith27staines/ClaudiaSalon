//
//  DeleteFromCloudOperation.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 01/05/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit


class DeleteFromCloudOperation : NSOperation {
    
    private var deletionInfo = DeletionInfo()
    private let containerID:String
    private let salonRecordName:String
    private let completionResult:(DeletionInfo)->Void
    private let cloudDatabase:CKDatabase
    private var operations = [NSOperation]()
    private var deleteOperationsForRecordType = [ICloudRecordType:[DeleteRecordTypeOperation]]()
    private let recordTypeOrder = [ICloudRecordType.Employee,
                                   ICloudRecordType.Customer,
                                   ICloudRecordType.Service,
                                   ICloudRecordType.ServiceCategory,
                                   ICloudRecordType.SaleItem,
                                   ICloudRecordType.Sale,
                                   ICloudRecordType.Appointment,
                                   ICloudRecordType.Salon]
    
    private let synchQueue:NSOperationQueue = {
        var queue = NSOperationQueue()
        queue.name = "DeleteFromCloud"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    init(containerID:String, salonRecordName:String, deletionInfo: DeletionInfo, completionResult:(DeletionInfo)->Void) {
        self.containerID = containerID
        let container = CKContainer(identifier: containerID)
        self.cloudDatabase = container.publicCloudDatabase
        self.salonRecordName = salonRecordName
        self.completionResult = completionResult
        self.deletionInfo = deletionInfo
        super.init()
    }
    
    override func main() {
        if self.cancelled { return }
        
        for recordType in self.recordTypeOrder {
            self.deleteOperationsForRecordType[recordType] = self.operationsForRecordType(recordType)
        }
        self.startNextOperation()
    }

    private func removeOperation(operation:DeleteRecordTypeOperation) {
        if var operations = self.deleteOperationsForRecordType[operation.recordType] {
            if let index = operations.indexOf(operation) {
                operations.removeAtIndex(index)
                self.deleteOperationsForRecordType[operation.recordType] = operations
            }
        }
    }
    
    private func startNextOperation() -> DeleteRecordTypeOperation? {
        guard let next = self.nextOperation() else {
            return nil
        }
        next.completionBlock = {
            self.synchQueue.addOperationWithBlock() {
                self.removeOperation(next)
                if let next = self.startNextOperation() {
                    self.deletionInfo.recordTypeInformation[next.recordType]?.status = .DeletingRecords
                }
            }
        }
        self.cloudDatabase.addOperation(next)
        return next
    }
    
    private func nextOperation() -> DeleteRecordTypeOperation? {
        for recordType in recordTypeOrder {
            if let operations = self.deleteOperationsForRecordType[recordType] {
                if let operation = operations.first {
                    operation.recordType = recordType
                    return operation
                }
            }
        }
        return nil
    }

    private func operationsForRecordType(recordType:ICloudRecordType) -> [DeleteRecordTypeOperation] {
        let maxRecords = 50
        var operations = [DeleteRecordTypeOperation]()
        let records = self.deletionInfo.recordTypeInformation[recordType]?.records
        if let records = records {
            let recordIDs = records.map({ (record) -> CKRecordID in
                return record.recordID
            })
            let fullOperationsRequired = records.count / maxRecords
            for i in 0 ..< fullOperationsRequired {
                let deleteOp = self.deleteRecordTypeOperation(recordType)
                let firstIndex = i * maxRecords
                let lastIndex = firstIndex + maxRecords - 1
                let slice = recordIDs[firstIndex...lastIndex]
                let recordIDs = [CKRecordID]() + slice
                deleteOp.recordIDsToDelete = recordIDs
                operations.append(deleteOp)
            }
            let remainder = records.count % maxRecords
            if remainder > 0 {
                let deleteOp = self.deleteRecordTypeOperation(recordType)
                let firstIndex = fullOperationsRequired * maxRecords
                let lastIndex = firstIndex + remainder - 1
                let slice = recordIDs[firstIndex...lastIndex]
                let recordIDs = [CKRecordID]() + slice
                deleteOp.recordIDsToDelete = recordIDs
                operations.append(deleteOp)
            }
        }
        return operations
    }
    
    
    func deleteWasCompleted(recordType:ICloudRecordType) {
        var allComplete = true
        var error = false
        for (_,recordInfo) in self.deletionInfo.recordTypeInformation {
            if recordInfo.status != .DeletingRecordsComplete {
                allComplete = false
            }
            if recordInfo.status == .ErrorDeletingRecords {
                error = true
            }
        }
        if error {
            self.deletionInfo.state = .FailedDeletion
        } else if allComplete {
            self.deletionInfo.state = .SuccessfulDeletion
        } else {
            self.deletionInfo.state = .DeletingRecords
        }
        self.completionResult(self.deletionInfo)
    }
}

extension DeleteFromCloudOperation {
    func deleteRecordTypeOperation(recordType:ICloudRecordType) -> DeleteRecordTypeOperation {

        let deleteOp = DeleteRecordTypeOperation()
        deleteOp.recordType = recordType
        
        let recordInfo = self.deletionInfo.recordTypeInformation[recordType]
        deleteOp.recordIDsToDelete = recordInfo?.records.map() { record in
            record.recordID
        }
        deleteOp.modifyRecordsCompletionBlock = { _, recordIDs, error in
            self.processDeletion(deleteOp, recordIDs: recordIDs, error: error)
        }
        
        return deleteOp
    }
    
    private func processDeletion(deleteOp:DeleteRecordTypeOperation, recordIDs:[CKRecordID]? ,error:NSError?) {
        self.synchQueue.addOperationWithBlock() {
            let recordType = deleteOp.recordType
            if error != nil {
                self.deletionInfo.recordTypeInformation[recordType]!.status = RecordTypeInfoStates.ErrorDeletingRecords
            } else {
                self.deletionInfo.recordTypeInformation[recordType]!.status = RecordTypeInfoStates.DeletingRecordsComplete
            }
            self.deleteWasCompleted(recordType)
        }
    }

    class DeleteRecordTypeOperation : CKModifyRecordsOperation {
        var recordType: ICloudRecordType!
    }
}


