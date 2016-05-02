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
                print("Failed to modify subscriptions with error \(operationError)")
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
    
    private func recordBelongsToSalon(record:CKRecord) -> Bool {
        if record.recordType == CloudRecordType.CRSalon.rawValue {
            return (record.recordID.recordName == self.cloudSalonRecordName)
        } else {
            guard let parentSalonReference = record["parentSalonReference"] as? CKReference else {
                return false
            }
            return (parentSalonReference.recordID.recordName == self.cloudSalonRecordName)
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
        fetchNotificationOperation.resultsLimit = 100
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

            var shallowProcessedNotificationIDs = [CKRecordID:Set<CKNotificationID>]()
            var notificationIDsToMarkRead = Set<CKNotificationID>()

            dispatch_sync(self.queue) {

                // Get array of possibly null IDs of records that have been modified in some way (including being created)
                var optionalRecordIDs = self.notifications.map { (notification) -> CKRecordID? in
                    return notification.recordID
                }
                // Filter out the null records
                optionalRecordIDs = optionalRecordIDs.filter({ (recordID) -> Bool in
                    return (recordID != nil)
                })
                // Convert the [CKRecordID?] (which now contains no nil entries) into an array of [CKRecordID]
                let changedRecordIDs:[CKRecordID] = optionalRecordIDs.map({ (recordID) -> CKRecordID in
                    return recordID!
                })
                
                var foreignNotificationIDsByRecordID = [CKRecordID:Set<CKNotificationID>]()
                let recordFetchOp = CKFetchRecordsOperation(recordIDs: changedRecordIDs)
                
                recordFetchOp.perRecordCompletionBlock = { (record,recordID,error) in
                    guard let recordID = recordID else {
                        return
                    }
                    guard let record = record else {
                        return
                    }
                    
                    guard self.recordBelongsToSalon(record) else {
                        // Reject this notification because it was for a different salon (i.e, a foreign salon) so we record its id in order to later mark it as read
                        for notification in self.notifications {
                            if notification.recordID == recordID {
                                var notes = foreignNotificationIDsByRecordID[recordID] ?? Set<CKNotificationID>()
                                notes.insert(notification.notificationID!)
                                foreignNotificationIDsByRecordID[recordID] = notes
                            }
                        }
                        return  // Reject foreign record
                    }
                    
                    // Shallow-process the record
                    print("Processing missed notification for \(record)")
                    self.shallowProcessRecord(record: record)
                    for notification in self.notifications {
                        if notification.recordID == recordID {
                            var notes = shallowProcessedNotificationIDs[recordID] ?? Set<CKNotificationID>()
                            notes.insert(notification.notificationID!)
                            shallowProcessedNotificationIDs[recordID] = notes
                        }
                    }
                }
                
                // Mark the notifications as read to avoid processing them again
                recordFetchOp.fetchRecordsCompletionBlock = { recordInfo, error in
                    if let recordInfo = recordInfo {
                        for (_,record) in recordInfo {
                            guard self.recordBelongsToSalon(record) else {
                                // Reject foreign records
                                continue
                            }
                            let deepProcessSuccess = self.deepProcessRecord(record: record)
                            if deepProcessSuccess {
                                let shallowProcessedNotifications = shallowProcessedNotificationIDs[record.recordID] ?? Set<CKNotificationID>()
                                notificationIDsToMarkRead.unionInPlace(shallowProcessedNotifications)
                            }
                        }
                    }
                    
                    for (_,foreignNotificationID) in foreignNotificationIDsByRecordID {
                        notificationIDsToMarkRead.unionInPlace(foreignNotificationID)
                    }

                    let markOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: Array(notificationIDsToMarkRead))
                    markOperation.markNotificationsReadCompletionBlock = { (notificationIDsMarkedRead: [CKNotificationID]?, operationError: NSError?) -> Void in
                        if operationError != nil {
                            // Handle the error here
                            return
                        }
                        if let processedCount = notificationIDsMarkedRead?.count {
                            let notice = NSNotification(name: "BadgeCountReducedNotification", object: self, userInfo: ["processed":processedCount])
                            NSNotificationCenter.defaultCenter().postNotification(notice)
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

extension CloudNotificationProcessor {
    func makeSubscriptionsArray() -> [CKSubscription] {
        
        var subscriptions = [CKSubscription]()
        let salonRecordID = CKRecordID(recordName: self.cloudSalonRecordName)
        let predicate = NSPredicate(format: "parentSalonReference == %@",salonRecordID)
        var subscription: CKSubscription
        var cloudRecordType:CloudRecordType
        var recordType:String
        var subscriptionID: String
        
        // iCloudSalon
        cloudRecordType = CloudRecordType.CRSalon
        recordType = cloudRecordType.rawValue
        subscriptionID = recordType + self.cloudSalonRecordName
        let salonPredicate = NSPredicate(format: "recordID == %@",salonRecordID)
        subscription = CKSubscription(recordType: recordType, predicate: salonPredicate, subscriptionID: subscriptionID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate])
        subscriptions.append(subscription)
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.desiredKeys = ["parentSalonReference"]
        
        // icloudAppointment
        let appointmentInfo = CKNotificationInfo()
        appointmentInfo.desiredKeys = notificationInfo.desiredKeys
        cloudRecordType = CloudRecordType.CRAppointment
        recordType = cloudRecordType.rawValue
        subscriptionID = recordType + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate])
        subscription.notificationInfo = appointmentInfo
        subscriptions.append(subscription)
        
        // icloudEmployee
        cloudRecordType = CloudRecordType.CREmployee
        recordType = cloudRecordType.rawValue
        subscriptionID = recordType + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate])
        subscription.notificationInfo = notificationInfo
        subscriptions.append(subscription)
        
        // icloudCustomer
        cloudRecordType = CloudRecordType.CRCustomer
        recordType = cloudRecordType.rawValue
        subscriptionID = recordType + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate])
        subscription.notificationInfo = notificationInfo
        subscriptions.append(subscription)
        
        // icloudServiceCategory
        cloudRecordType = CloudRecordType.CRServiceCategory
        recordType = cloudRecordType.rawValue
        subscriptionID = recordType + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate])
        subscription.notificationInfo = notificationInfo
        subscriptions.append(subscription)
        
        // icloudService
        cloudRecordType = CloudRecordType.CRService
        recordType = cloudRecordType.rawValue
        subscriptionID = recordType + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate])
        subscription.notificationInfo = notificationInfo
        subscriptions.append(subscription)
        return subscriptions
    }
}

extension CloudNotificationProcessor {
    func deleteAllCloudNotificationSubscriptions() {
        let db = self.container.publicCloudDatabase
        let fetchSubscriptions = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
        fetchSubscriptions.fetchSubscriptionCompletionBlock = { dictionary, error in
            guard let dictionary = dictionary else {
                print("error fetching subscriptions \(error)")
                return
            }
            var subscriptionIDs = [String]()
            for (subscriptionID,_) in dictionary {
                subscriptionIDs.append(subscriptionID)
            }
            let deleteSubscriptions = CKModifySubscriptionsOperation(subscriptionsToSave: nil, subscriptionIDsToDelete: subscriptionIDs)
            deleteSubscriptions.modifySubscriptionsCompletionBlock = { _,subscriptionIDs,error in
                if error != nil {
                    print("error deleting subscriptions \(error)")
                    return
                }
                print("All subscriptions deleted")
            }
            db.addOperation(deleteSubscriptions)
        }
        db.addOperation(fetchSubscriptions)
    }
}
