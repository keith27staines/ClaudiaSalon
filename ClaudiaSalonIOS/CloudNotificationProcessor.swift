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
    private var processingSuspended = true
    lazy var subscriptions: [CKSubscription] = {
        return self.makeSubscriptionsArray()
    }()

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
        self.subscribeToCloudNotifications()
    }
    
    func forgetSalon(completion:((success:Bool)->Void)) {
        self.suspendNotificationProcessing()
        let subscriptionIDs = self.subscriptions.map {
            subscription in
            return subscription.subscriptionID
        }
        let deleteSubscriptionsOperation = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: subscriptionIDs)
        deleteSubscriptionsOperation.modifySubscriptionsCompletionBlock = { _, subscriptionIDs, error in
            if let error = error {
                let userInfo = error.userInfo
                let errorCode = CKErrorCode(rawValue: error.code)!
                switch errorCode {
                case .PartialFailure:
                    var okToComplete = true
                    let errorsByID = userInfo[CKPartialErrorsByItemIDKey] as! [String:NSError]
                    for (_,error) in errorsByID {
                        if error.code != CKErrorCode.UnknownItem.rawValue {
                            okToComplete = false
                        }
                    }
                    if okToComplete {
                        print("Subscriptions deleted")
                    } else {
                        print("Failed to delete subscriptions")
                    }
                    completion(success: okToComplete)
                default:
                    print("Subscriptions deleted")
                    completion(success: false)
                }
                return
            }
            completion(success: true)
        }
        self.container.publicCloudDatabase.addOperation(deleteSubscriptionsOperation)
    }
    
    func isSuspended() -> Bool {
        return self.processingSuspended
    }
    func suspendNotificationProcessing() {
        self.processingSuspended = true
    }
    func resumeNotificationProcessing() {
        self.processingSuspended = false
        self.pollForMissedRemoteNotifications()
    }
    
    func subscribeToCloudNotifications() {
        self.saveSubscriptions()
    }
    
    private func saveSubscriptions() {
        let modifySubscriptions = CKModifySubscriptionsOperation(subscriptionsToSave: self.subscriptions, subscriptionIDsToDelete: nil)
        modifySubscriptions.queuePriority = .VeryHigh
        modifySubscriptions.modifySubscriptionsCompletionBlock = { (savedSubscriptions, deletedIDs, operationError) -> Void in
            if let operationError = operationError {
                let retryAfter = operationError.userInfo["retryAfter"] as? Int
                if let retryAfter = retryAfter {
                    let shortDelay = dispatch_time(DISPATCH_TIME_NOW, Int64(retryAfter))
                    let mainQueue = dispatch_get_main_queue()
                    print("Transient subscription error - will retry after \(retryAfter) seconds")
                    dispatch_after(shortDelay, mainQueue) {
                        self.saveSubscriptions()
                    }
                    return
                }
                assertionFailure("Failed to modify subscriptions with error \(operationError)")
                return
            }
            print("All subscriptions saved - Begun listening for cloud notifications")
            NSNotificationCenter.defaultCenter().addObserverForName("cloudKitNotification", object: nil, queue: nil, usingBlock: self.notificationFromCloud)
            self.pollForMissedRemoteNotifications()
        }
        self.publicCloudDatabase.addOperation(modifySubscriptions)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func notificationFromCloud(notification:NSNotification) {
        if self.processingSuspended {
            return
        }
        self.pollForMissedRemoteNotifications()
    }

    func pollForMissedRemoteNotifications() {
        if self.processingSuspended {
            return
        }
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
                        let notice = NSNotification(name: "BadgeCountReducedNotification", object: self, userInfo: ["processed":5])
                        
                        NSNotificationCenter.defaultCenter().postNotification(notice)
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

extension CloudNotificationProcessor {
    func makeSubscriptionsArray() -> [CKSubscription] {
        
        var subscriptions = [CKSubscription]()
        let salonRecordID = CKRecordID(recordName: self.cloudSalonRecordName)
        let predicate = NSPredicate(format: "parentSalonReference == %@",salonRecordID)
        var subscription: CKSubscription
        var CRT:CloudRecordType
        var crt:String
        var subID: String
        
        //        // iCloudSalon
        //        let salonRecordID = CKRecordID(recordName: self.cloudSalonRecordName)
        //        let salonPredicate = NSPredicate(format: "recordID = %@", salonRecordID)
        //        subscription = CKSubscription(recordType: "iCloudSalon", predicate: salonPredicate, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        //        subscriptionsDictionary[subscription.recordType!] = subscription
        
        // icloudAppointment
        let appointmentInfo = CKNotificationInfo()
        appointmentInfo.alertBody = "Salon appointment was updated";
        appointmentInfo.shouldBadge = true;
        CRT = CloudRecordType.CRAppointment
        crt = CRT.rawValue
        subID = crt + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: crt, predicate: predicate, subscriptionID: subID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscription.notificationInfo = appointmentInfo
        subscriptions.append(subscription)
        
        // icloudEmployee
        CRT = CloudRecordType.CREmployee
        crt = CRT.rawValue
        subID = crt + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: crt, predicate: predicate, subscriptionID: subID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscriptions.append(subscription)
        
        // icloudCustomer
        CRT = CloudRecordType.CRCustomer
        crt = CRT.rawValue
        subID = crt + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: crt, predicate: predicate, subscriptionID: subID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscriptions.append(subscription)
        
        // icloudSale
        CRT = CloudRecordType.CRSale
        crt = CRT.rawValue
        subID = crt + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: crt, predicate: predicate, subscriptionID: subID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscriptions.append(subscription)
        
        // icloudSaleItem
        CRT = CloudRecordType.CRSaleItem
        crt = CRT.rawValue
        subID = crt + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: crt, predicate: predicate, subscriptionID: subID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscriptions.append(subscription)
        
        // icloudServiceCategory
        CRT = CloudRecordType.CRServiceCategory
        crt = CRT.rawValue
        subID = crt + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: crt, predicate: predicate, subscriptionID: subID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscriptions.append(subscription)
        
        // icloudService
        CRT = CloudRecordType.CRService
        crt = CRT.rawValue
        subID = crt + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: crt, predicate: predicate, subscriptionID: subID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate, .FiresOnRecordDeletion])
        subscriptions.append(subscription)
        return subscriptions
    }
}
