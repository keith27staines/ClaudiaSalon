
//
//  BQChangeMonitor.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

class BQChangeMonitor {
    let queue = NSOperationQueue()
    var recordsToDelete = Set<CKRecordID>()
    let publicDatabase = CKContainer.defaultContainer().publicCloudDatabase
    init() {
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: nil, queue: queue) { notification in
            if let updated = notification.userInfo?[NSUpdatedObjectsKey] where updated.count > 0 {
                print("updated: \(updated)")
            }
            
            if let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] {
                print("deleted: \(deletedObjects)")
                let deletedSet = deletedObjects as! Set<NSManagedObject>
                self.sendDeletedCoredataObjectsToBQDeletionQueue(deletedSet)
            }
            
            if let inserted = notification.userInfo?[NSInsertedObjectsKey] where inserted.count > 0 {
                print("inserted: \(inserted)")
            }
            self.queue.addOperationWithBlock({ () -> Void in
                
            })
        }
    }
    func processRecordsForDeletion(deleteRecords:Set<CKRecordID>) {
        let database = publicDatabase
        let deleteOperation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: Array(deleteRecords))
        deleteOperation.modifyRecordsCompletionBlock = { (_,recordIDsToDelete,error)->Void in
            guard let recordIDsToDelete = recordIDsToDelete else { return }
            if let error = error {
                if error.errorType == CKErrorPartialFailure {
                    // CKPartialErrorsByItemIDKey
                }
            }
            let failedDeletions:Set<CKRecordID>
            let deletedRecordIDs = recordIDsToDelete.filter({ (recordID) -> Bool in
                return !failedDeletions.contains(recordID)
            })
            dispatch_sync(dispatch_get_main_queue(), {
                for recordID in deletedRecordIDs {
                    self.recordsToDelete.remove(recordID)
                }
            })
        }
        database.addOperation(deleteOperation)
    }
    func sendDeletedCoredataObjectsToBQDeletionQueue(deletedRecords:Set<NSManagedObject>) {
        for managedObject in deletedRecords {
            guard let (metadata,_) = bqdataFromManagedObject(managedObject) else {
                continue
            }
            guard metadata != nil else {
                continue // If there is no metadata then there will be no matching record in the cloud so we are done
            }
            guard let record = ckRecordFromMetadata(metadata!) else {
                print("Unable to decode cloudkit record from metadata in coredata object")
                continue
            }
            recordsToDelete.insert(record.recordID)
        }
    }
    func ckRecordFromMetadata(metadata:NSData) -> CKRecord? {
        let unarchiver = NSKeyedUnarchiver(forReadingWithData: metadata)
        return CKRecord(coder: unarchiver)
    }
    func bqdataFromManagedObject(managedObject:NSManagedObject) -> (metadata:NSData?,bqNeedsExport:Bool)? {
        let className = managedObject.className
        switch className {
        case Salon.className():
            let salon = managedObject as! Salon
            return (salon.bqMetadata,salon.bqNeedsCoreDataExport!.boolValue)
        case Employee.className():
            let employee = managedObject as! Employee
            return (employee.bqMetadata,employee.bqNeedsCoreDataExport!.boolValue)
        case Customer.className():
            let customer = managedObject as! Customer
            return (customer.bqMetadata,customer.bqNeedsCoreDataExport!.boolValue)
        case ServiceCategory.className():
            let serviceCategory = managedObject as! ServiceCategory
            return (serviceCategory.bqMetadata,serviceCategory.bqNeedsCoreDataExport!.boolValue)
        case Service.className():
            let service = managedObject as! Service
            return (service.bqMetadata,service.bqNeedsCoreDataExport!.boolValue)
        case Appointment.className():
            let appointment = managedObject as! Appointment
            return (appointment.bqMetadata,appointment.bqNeedsCoreDataExport!.boolValue)
        case Sale.className():
            let sale = managedObject as! Sale
            return (sale.bqMetadata,sale.bqNeedsCoreDataExport!.boolValue)
        case SaleItem.className():
            let saleItem = managedObject as! SaleItem
            return (saleItem.bqMetadata,saleItem.bqNeedsCoreDataExport!.boolValue)
        default:
            return nil
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}