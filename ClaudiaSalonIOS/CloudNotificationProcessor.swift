//
//  CloudNotificationProcessor.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

class CloudNotificationProcessor {
    var shallowProcessRecord: ((record:CKRecord)->Void)
    var deepProcessRecord: ((record:CKRecord)->Bool)
    private (set) var cloudContainerIdentifier:String
    private (set) var cloudSalonRecordName:String
    private let queue:dispatch_queue_t
    private var isWorking = false
    private var previousServerChangeToken:CKServerChangeToken?
    private var notifications = [CKQueryNotification]()
    private var container:CKContainer
    private let publicCloudDatabase:CKDatabase
    
    private let cloudSalonReference : CKReference!

    init(cloudContainerIdentifier:String, cloudSalonRecordName:String) {
        let salonID = CKRecordID(recordName: cloudSalonRecordName)
        self.cloudSalonReference = CKReference(recordID: salonID, action: .None)
        self.cloudSalonRecordName = cloudSalonRecordName
        self.cloudContainerIdentifier = cloudContainerIdentifier
        self.container = CKContainer(identifier: self.cloudContainerIdentifier)
        self.publicCloudDatabase = self.container.publicCloudDatabase
        self.queue = dispatch_queue_create("CloudNotificationProcessor", DISPATCH_QUEUE_SERIAL)
        self.shallowProcessRecord = {(record)->Void in
            assertionFailure("The shallowProcessRecord block cannot be called because it was never set")
        }
        self.deepProcessRecord = {(record)->Bool in
            assertionFailure("The deepProcessRecord block cannot be called because it was never set")
            return false
        }
    }
    
    func subscribeToCloudNotifications() {

        let predicate = NSPredicate(format: "parentSalonReference == %@",self.cloudSalonReference)
        var subscription: CKSubscription

        // iCloudSalon
        subscription = CKSubscription(recordType: "iCloudSalon", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        self.saveSubscription(subscription)

        // icloudAppointment
        subscription = CKSubscription(recordType: "icloudAppointment", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])

        // icloudCustomer
        subscription = CKSubscription(recordType: "icloudCustomer", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        self.saveSubscription(subscription)

        // icloudSale
        subscription = CKSubscription(recordType: "icloudSale", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        self.saveSubscription(subscription)

        // icloudSaleItem
        subscription = CKSubscription(recordType: "icloudSaleItem", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        self.saveSubscription(subscription)

        // icloudServiceCategory
        subscription = CKSubscription(recordType: "icloudServiceCategory", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        self.saveSubscription(subscription)

        // icloudService
        subscription = CKSubscription(recordType: "iCloudService", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        self.saveSubscription(subscription)
        
        NSNotificationCenter.defaultCenter().addObserverForName("cloudKitNotification", object: nil, queue: nil, usingBlock: self.notificationFromCloud)
    }
    
    private func saveSubscription(subscription:CKSubscription) {
        self.publicCloudDatabase.saveSubscription(subscription) { (subscription, error) in
            if error != nil {
                //assertionFailure("Error saving cloud notification subscription \(error)")
                return
            }
        }
    }

    func notificationFromCloud(notification:NSNotification) {
        let userInfo = notification.userInfo!
        let cloudKitNotification = CKNotification(fromRemoteNotificationDictionary: userInfo as! [String : NSObject])
        let queryNotification = cloudKitNotification as! CKQueryNotification
        if queryNotification.queryNotificationReason == .RecordDeleted {
            // If the record has been deleted in CloudKit then delete the local copy
        } else {
            // If the record has been created or changed, we fetch the data from CloudKit
            let database: CKDatabase
            if queryNotification.isPublicDatabase {
                database = self.container.publicCloudDatabase
            } else {
                database = self.container.privateCloudDatabase
            }
            database.fetchRecordWithID(queryNotification.recordID!) { (record: CKRecord?, error: NSError?) -> Void in
                guard error == nil else {
                    // Handle the error here
                    return
                }
                self.shallowProcessRecord(record: record!)
            }
        }
        self.pollForMissedRemoteNotifications()
    }

    func pollForMissedRemoteNotifications() {
        self.pollForMissedRemoteNotifications(0)
    }

    private func pollForMissedRemoteNotifications(secondsDelay:Double) {
        let nanosecondsDelay = Int64(secondsDelay) * Int64(NSEC_PER_SEC)
        let when = dispatch_time(DISPATCH_TIME_NOW, nanosecondsDelay)
        dispatch_after(when, self.queue) {
            if self.isWorking {
                self.pollForMissedRemoteNotifications(1)
                return
            }
            self.isWorking = true
            self.performNotificationFetch()
        }
    }
    
    private func performNotificationFetch(serverChangeToken: CKServerChangeToken? = nil) {

        // Create fetch notifications operation
        let fetchNotificationOperation = CKFetchNotificationChangesOperation(previousServerChangeToken: nil)
        
        // The callback for when a notification is returned from the fetch
        fetchNotificationOperation.notificationChangedBlock = { (notification: CKNotification) -> Void in
            
            // If the notification is a query type then add it to the array for future processing
            if notification.notificationType == .Query {
                let queryNotification = notification as! CKQueryNotification
                
                // Add the notification id to the array of processed notifications to mark them as read
                self.notifications.append(queryNotification)
            }
        }
        
        // The callback for the fetch completion
        fetchNotificationOperation.fetchNotificationChangesCompletionBlock = { (serverChangeToken: CKServerChangeToken?, operationError: NSError?) -> Void in
    
            guard operationError == nil else {
                dispatch_sync(self.queue) {
                    self.notifications.removeAll()
                    self.isWorking = false
                }
                return
            }

            dispatch_sync(self.queue) {

                // Get array of possibly null IDs of records that have been modified in some way (including being created)
                var optionalRecordIDs = self.notifications.map { (notification) -> CKRecordID? in
                    return notification.recordID
                }
                // Filter out the null records
                optionalRecordIDs = optionalRecordIDs.filter({ (recordID) -> Bool in
                    return (recordID != nil)
                })
                // Convert the [CKRecordID?] (which now contains no nil entries) into an array of [CKRecord]
                let changedRecordIDs:[CKRecordID] = optionalRecordIDs.map({ (recordID) -> CKRecordID in
                    return recordID!
                })
                
                let recordFetchOp = CKFetchRecordsOperation(recordIDs: changedRecordIDs)
                var processedNotificationIDs = [CKRecordID:Set<CKNotificationID>]()
                
                recordFetchOp.perRecordCompletionBlock = { (record,recordID,error) in
                    guard let recordID = recordID else {
                        return
                    }
                    guard let record = record else {
                        return
                    }
                    guard let parentSalonReference = record["parentSalonReference"] as? CKReference else {
                        return
                    }
                    guard parentSalonReference.recordID.recordName == self.cloudSalonRecordName else {
                        return
                    }
                    
                    // Shallow-process the record
                    print("Processing missed notification for \(record)")
                    self.shallowProcessRecord(record: record)
                    for notification in self.notifications {
                        if notification.recordID == recordID {
                            var notes:Set<CKNotificationID>
                            notes = processedNotificationIDs[recordID] ?? Set<CKNotificationID>()
                            notes.insert(notification.notificationID!)
                        }
                    }
                }
                
                // Mark the notifications as read to avoid processing them again
                recordFetchOp.fetchRecordsCompletionBlock = { recordInfo, error in
                    var notificationIDsToMarkRead = Set<CKNotificationID>()
                    if let recordInfo = recordInfo {
                        for (_,record) in recordInfo {
                            let deepProcessSuccess = self.deepProcessRecord(record: record)
                            if deepProcessSuccess {
                                let notificationIDsReferencingRecord = processedNotificationIDs[record.recordID] ?? Set<CKNotificationID>()
                                notificationIDsToMarkRead.unionInPlace(notificationIDsReferencingRecord)
                            }
                        }
                    }

                    let markOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: Array(notificationIDsToMarkRead))
                    markOperation.markNotificationsReadCompletionBlock = { (notificationIDsMarkedRead: [CKNotificationID]?, operationError: NSError?) -> Void in
                        if operationError != nil {
                            // Handle the error here
                            return
                        }
                        self.notifications.removeAll()
                        self.isWorking = false
                    }
                    self.container.addOperation(markOperation)
                }
                
                // Having set up all the callback blocks, we can now execute the fetchNotification operation
                self.container.publicCloudDatabase.addOperation(recordFetchOp)
            }
            
            // The previous fetch may only have returned some of the missed notifications so now we check for more
            if fetchNotificationOperation.moreComing {
                self.performNotificationFetch(serverChangeToken)
            }
        }
        self.container.addOperation(fetchNotificationOperation)
    }
}
