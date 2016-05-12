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
    var moc: NSManagedObjectContext!
    private (set) var cloudContainerIdentifier:String
    private (set) var cloudSalonRecordName:String
    private let queue:dispatch_queue_t
    private var isWorking = false
    private var previousServerChangeToken:CKServerChangeToken?
    private var container:CKContainer
    private let publicCloudDatabase:CKDatabase
    private var currentSubscription: CKSubscription!
    private let cloudSalonReference : CKReference!
    private var processingSuspended = true
    
    lazy var cloudSubscriber: CloudNotificationSubscriber = {
        return CloudNotificationSubscriber(database: self.publicCloudDatabase, cloudSalonRecordName: self.cloudSalonRecordName)
    }()

    private var importers = [CKRecordID:RobustImporter]()
    private var notifications = [CKQueryNotification]()

    init(cloudContainerIdentifier:String, cloudSalonRecordName:String) {
        let salonID = CKRecordID(recordName: cloudSalonRecordName)
        self.cloudSalonReference = CKReference(recordID: salonID, action: .None)
        self.cloudSalonRecordName = cloudSalonRecordName
        self.cloudContainerIdentifier = cloudContainerIdentifier
        self.container = CKContainer(identifier: self.cloudContainerIdentifier)
        self.publicCloudDatabase = self.container.publicCloudDatabase
        self.queue = dispatch_queue_create("CloudNotificationProcessor", DISPATCH_QUEUE_SERIAL)
        self.subscribeToCloudNotifications()
    }
    
    func forgetSalon(completion:((success:Bool)->Void)) {
        self.suspendNotificationProcessing()
        self.cloudSubscriber.deleteSubscriptions(completion)
    }
    func deleteAllCloudNotificationSubscriptions() {
        self.cloudSubscriber.deleteAllCloudNotificationSubscriptions()
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
        self.cloudSubscriber.saveSubscriptions { success in
            guard success else {return}
            print("All subscriptions saved - Begun listening for cloud notifications")
            NSNotificationCenter.defaultCenter().addObserverForName("cloudKitNotification", object: nil, queue: nil, usingBlock: self.notificationFromCloud)
            self.pollForMissedRemoteNotifications()
        }
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
            self.prepareForNewFetch()
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
    
    private func prepareForNewFetch() {
        self.importers.removeAll()
        self.notifications.removeAll()
    }
    
    private func performNotificationFetch(serverChangeToken: CKServerChangeToken? = nil) {
        
        // Create fetch notifications operation
        let fetchNotificationOperation = CKFetchNotificationChangesOperation(previousServerChangeToken: nil)
        fetchNotificationOperation.resultsLimit = 100
        
        // Set the per-notification block
        fetchNotificationOperation.notificationChangedBlock = self.notificationChanged
        
        // Set the fetch completion block
        fetchNotificationOperation.fetchNotificationChangesCompletionBlock = { serverChangeToken, operationError in
            self.fetchNotificationsCompleted(fetchNotificationOperation.moreComing, serverChangeToken: serverChangeToken, operationError: operationError)
        }
        self.container.addOperation(fetchNotificationOperation)
    }
}

extension CloudNotificationProcessor : RobustImporterDelegate {
    func importDidFail(importer: RobustImporter) {
        
    }
    func importDidProgressState(importer: RobustImporter) {
        
    }
}

extension CloudNotificationProcessor {
    private func importerForRecordType(recordType:String, recordID: CKRecordID) -> RobustImporter {
        guard let type = ICloudRecordType(rawValue: recordType) else {
            fatalError("There is no importer for records of type \(recordType)")
        }
        switch type {
        case .Salon:
            return SalonImporter(key: "salon", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, delegate: self)
        case .Customer:
            return CustomerImporter(key: "customer", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, delegate: self)
        case .Employee:
            return EmployeeImporter(key: "employee", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, delegate: self)
        case .ServiceCategory:
            return ServiceCategoryImporter(key: "serviceCategory", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, delegate: self)
        case .Service:
            return ServiceImporter(key: "service", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, delegate: self)
        case .Appointment:
            return AppointmentImporter(key: "appointment", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, delegate: self)
        case .Sale:
            return SaleImporter(key: "sale", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, delegate: self)
        case .SaleItem:
            return SaleItemImporter(key: "saleItem", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, delegate: self)
        }
    }
}
extension CloudNotificationProcessor {
    
    private func notificationChanged(notification: CKNotification) {
        // If the notification is a query type then add it to the array for future processing
        if notification.notificationType == .Query {
            let queryNotification = notification as! CKQueryNotification
            
            // Add the notification id to the array of processed notifications to mark them as read
            self.notifications.append(queryNotification)
        }
    }

    private func fetchNotificationsCompleted(moreComing:Bool, serverChangeToken: CKServerChangeToken?, operationError: NSError?) {
        guard operationError == nil else {
            dispatch_sync(self.queue) {
                self.isWorking = false
            }
            return
        }

        // The previous operation might have returned only a subset of the missed notifications so now we check for more
        if moreComing {
            self.performNotificationFetch(serverChangeToken)
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
                        //let deepProcessSuccess = self.deepProcessRecord(record: record)
//                        if deepProcessSuccess {
//                            let shallowProcessedNotifications = shallowProcessedNotificationIDs[record.recordID] ?? Set<CKNotificationID>()
//                            notificationIDsToMarkRead.unionInPlace(shallowProcessedNotifications)
//                        }
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
    }
}
