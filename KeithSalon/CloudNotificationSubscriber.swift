//
//  CloudNotificationSubscriber.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 12/05/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit


class CloudNotificationSubscriber {
    private let database:CKDatabase
    private let queue: dispatch_queue_t
    private let cloudSalonRecordName: String
    lazy var subscriptions: [CKSubscription] = {
        return self.makeSubscriptionsArray()
    }()
    
    init(database:CKDatabase, cloudSalonRecordName:String) {
        self.database = database
        self.cloudSalonRecordName = cloudSalonRecordName
        self.queue = dispatch_queue_create("CloudNotificationProcessor", DISPATCH_QUEUE_SERIAL)
    }
    
    func deleteSubscriptions(completion:(success:Bool)->Void) {
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
        self.database.addOperation(deleteSubscriptionsOperation)
    }
    
    func saveSubscriptions(completion:(success:Bool)->Void) {
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
                        self.saveSubscriptions(completion)
                    }
                    return
                }
                print("Failed to modify subscriptions with error \(operationError)")
                completion(success: false)
                return
            }
            print("Saved cloud notification subscriptions")
            completion(success: true)
        }
        self.database.addOperation(modifySubscriptions)
    }
}

extension CloudNotificationSubscriber {
    class func deleteAllCloudNotificationSubscriptions(database:CKDatabase, completion:((Result)->Void)) {
        let fetchSubscriptions = CKFetchSubscriptionsOperation.fetchAllSubscriptionsOperation()
        fetchSubscriptions.fetchSubscriptionCompletionBlock = { dictionary, error in
            guard error == nil else {
                print("Error fetching subsciptions: \(error)")
                let r = Result.failure(error!)
                completion(r)
                return
            }
            guard let dictionary = dictionary else {
                let r = Result.success
                completion(r)
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
                    let r = Result.failure(error!)
                    completion(r)
                    return
                }
                print("All subscriptions deleted")
                let r = Result.success
                completion(r)
            }
            database.addOperation(deleteSubscriptions)
        }
        database.addOperation(fetchSubscriptions)
    }
}

extension CloudNotificationSubscriber {
    func makeSubscriptionsArray() -> [CKSubscription] {
        
        var subscriptions = [CKSubscription]()
        let salonRecordID = CKRecordID(recordName: self.cloudSalonRecordName)
        let predicate = NSPredicate(format: "parentSalonReference == %@",salonRecordID)
        var subscription: CKSubscription
        var cloudRecordType:ICloudRecordType
        var recordType:String
        var subscriptionID: String
        
        // iCloudSalon
        cloudRecordType = ICloudRecordType.CRSalon
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
        cloudRecordType = ICloudRecordType.CRAppointment
        recordType = cloudRecordType.rawValue
        subscriptionID = recordType + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate])
        subscription.notificationInfo = appointmentInfo
        subscriptions.append(subscription)
        
        // icloudEmployee
        cloudRecordType = ICloudRecordType.CREmployee
        recordType = cloudRecordType.rawValue
        subscriptionID = recordType + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate])
        subscription.notificationInfo = notificationInfo
        subscriptions.append(subscription)
        
        // icloudCustomer
        cloudRecordType = ICloudRecordType.CRCustomer
        recordType = cloudRecordType.rawValue
        subscriptionID = recordType + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate])
        subscription.notificationInfo = notificationInfo
        subscriptions.append(subscription)
        
        // icloudServiceCategory
        cloudRecordType = ICloudRecordType.CRServiceCategory
        recordType = cloudRecordType.rawValue
        subscriptionID = recordType + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate])
        subscription.notificationInfo = notificationInfo
        subscriptions.append(subscription)
        
        // icloudService
        cloudRecordType = ICloudRecordType.CRService
        recordType = cloudRecordType.rawValue
        subscriptionID = recordType + self.cloudSalonRecordName
        subscription = CKSubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: [.FiresOnRecordCreation, .FiresOnRecordUpdate])
        subscription.notificationInfo = notificationInfo
        subscriptions.append(subscription)
        return subscriptions
    }
}
