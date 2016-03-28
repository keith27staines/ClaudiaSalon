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
    var processRecord: ((record:CKRecord)->Void)
    private (set) var cloudContainerIdentifier:String
    private (set) var cloudSalonRecordName:String
    private let queue:dispatch_queue_t
    private var isWorking = false
    private var previousServerChangeToken:CKServerChangeToken?
    private var notifications = [CKQueryNotification]()
    private var container:CKContainer
    
    init(cloudContainerIdentifier:String, cloudSalonRecordName:String) {
        self.cloudSalonRecordName = cloudSalonRecordName
        self.cloudContainerIdentifier = cloudContainerIdentifier
        self.container = CKContainer(identifier: self.cloudContainerIdentifier)
        queue = dispatch_queue_create("CloudNotificationProcessor", DISPATCH_QUEUE_SERIAL)
        self.processRecord = {(record)->Void in  }
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
                var processedNotificationIDs = Set<CKNotificationID>()
                recordFetchOp.perRecordCompletionBlock = { (record,recordID,error) in
                    guard let record = record else {
                        return
                    }
                    guard let parentSalonReference = record["parentSalonReference"] as? CKReference else {
                        return
                    }
                    guard parentSalonReference.recordID.recordName == self.cloudSalonRecordName else {
                        return
                    }
                    print("Processing missed notification for \(record)")
                    self.processRecord(record: record)
                    for notification in self.notifications {
                        if notification.recordID == recordID {
                            processedNotificationIDs.insert(notification.notificationID!)
                        }
                    }
                }
                
                // Mark the notifications as read to avoid processing them again
                recordFetchOp.fetchRecordsCompletionBlock = { recordInfo, error in
                    let notificationIDsToMarkRead = Array(processedNotificationIDs)
                    let markOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: notificationIDsToMarkRead)
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
