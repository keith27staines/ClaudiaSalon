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
    private var currentSubscription: CKSubscription!
    private let cloudSalonReference : CKReference!
    var subscriptionsDictionary = [String:CKSubscription]()

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

        //let predicate = NSPredicate(format: "parentSalonReference = %@",self.cloudSalonReference)
        let predicate = NSPredicate(value: true)
        var subscription: CKSubscription

//        // iCloudSalon
//        let salonRecordID = CKRecordID(recordName: self.cloudSalonRecordName)
//        let salonPredicate = NSPredicate(format: "recordID = %@", salonRecordID)
//        subscription = CKSubscription(recordType: "iCloudSalon", predicate: salonPredicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
//        subscriptionsDictionary[subscription.recordType!] = subscription

        // icloudAppointment
        subscription = CKSubscription(recordType: "icloudAppointment", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscriptionsDictionary[subscription.recordType!] = subscription
        
        // icloudEmployee
        subscription = CKSubscription(recordType: "icloudEmployee", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscriptionsDictionary[subscription.recordType!] = subscription

        // icloudCustomer
        subscription = CKSubscription(recordType: "icloudCustomer", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscriptionsDictionary[subscription.recordType!] = subscription

        // icloudSale
        subscription = CKSubscription(recordType: "icloudSale", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscriptionsDictionary[subscription.recordType!] = subscription

        // icloudSaleItem
        subscription = CKSubscription(recordType: "icloudSaleItem", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscriptionsDictionary[subscription.recordType!] = subscription

        // icloudServiceCategory
        subscription = CKSubscription(recordType: "icloudServiceCategory", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscriptionsDictionary[subscription.recordType!] = subscription

        // icloudService
        subscription = CKSubscription(recordType: "iCloudService", predicate: predicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscriptionsDictionary[subscription.recordType!] = subscription
        
        self.saveSubscriptions()
        
    }
    
    private func saveSubscriptions() {
        if let subscriptionInfo = self.subscriptionsDictionary.first {
            self.currentSubscription = subscriptionInfo.1
            self.saveSubscription(currentSubscription)
        }
        if self.subscriptionsDictionary.count == 0 {
            print("Yay!!!!! All subscriptions saved!")
            NSNotificationCenter.defaultCenter().addObserverForName("cloudKitNotification", object: nil, queue: nil, usingBlock: self.notificationFromCloud)
            self.pollForMissedRemoteNotifications()
        }
    }
    
    private func saveSubscription(subscription:CKSubscription) {
        let shortDelay = dispatch_time(DISPATCH_TIME_NOW, 100)
        let mainQueue = dispatch_get_main_queue()
        var removeFromList = true
        self.publicCloudDatabase.saveSubscription(subscription) { (subscription, error) in
            var fatal = false
            if let error = error {
                removeFromList = false
                switch error.code {
                case CKErrorCode.NetworkFailure.rawValue:
                    fatal = true
                    break
                case CKErrorCode.NetworkUnavailable.rawValue:
                    fatal = true
                    break
                case CKErrorCode.NotAuthenticated.rawValue:
                    fatal = true
                    break
                case CKErrorCode.InvalidArguments.rawValue:
                    fatal = true
                    break
                case CKErrorCode.MissingEntitlement.rawValue:
                    fatal = true
                    break
                case CKErrorCode.LimitExceeded.rawValue:
                    fatal = false
                    break
                case CKErrorCode.PermissionFailure.rawValue:
                    fatal = true
                    break
                case CKErrorCode.QuotaExceeded.rawValue:
                    fatal = true
                    break
                case CKErrorCode.ServiceUnavailable.rawValue:
                    fatal = true
                    break
                case CKErrorCode.ServerRejectedRequest.rawValue:
                    print("Subscription exists and wasn't saved again")
                    removeFromList = true
                    fatal = false
                    break
                case CKErrorCode.UnknownItem.rawValue:
                    removeFromList = true
                    fatal = false
                    break
                default:
                    fatal = true
                    break
                }
            }
            if removeFromList {
                let type = self.currentSubscription.recordType!
                self.subscriptionsDictionary[type] = nil
                print("Subscription is saved")
                dispatch_after(shortDelay, mainQueue) {
                    self.saveSubscriptions()
                }
            } else if fatal {
                assertionFailure("Fatal error while saving subscriptions: \(error)")
            }
        }
    }

    func notificationFromCloud(notification:NSNotification) {
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
            guard self.notifications.count > 0 else {
                dispatch_sync(self.queue) {
                    self.isWorking = false
                }
                return
            }
            
            guard operationError == nil else {
                dispatch_sync(self.queue) {
                    self.notifications.removeAll()
                    self.isWorking = false
                }
                return
            }
            
            var processedNotificationIDs = [CKRecordID:Set<CKNotificationID>]()
            for notification in self.notifications {
                if notification.queryNotificationReason == .RecordDeleted {
                    var notes = processedNotificationIDs[notification.recordID!] ?? Set<CKNotificationID>()
                    notes.insert(notification.notificationID!)
                    processedNotificationIDs[notification.recordID!] = notes
                }
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
                            processedNotificationIDs[recordID] = notes
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
