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
    private var importState: RobustImporter.ImportState = RobustImporter.ImportState.InPreparation
    
    lazy var cloudSubscriber: CloudNotificationSubscriber = {
        return CloudNotificationSubscriber(database: self.publicCloudDatabase, cloudSalonRecordName: self.cloudSalonRecordName)
    }()

    private var downloadedNotifications = [CKQueryNotification]()
    private var recordDataByRecordID = [CKRecordID:RecordData]()
    private var notificationsToMarkRead = Set<CKQueryNotification>()
    
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
            print("Begin listening for local notifications")
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
            self.prepareToFetchNotifications()
            self.beginNotificationFetch()
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
    
    private func prepareToFetchNotifications() {
        self.downloadedNotifications.removeAll()
        self.notificationsToMarkRead.removeAll()
        self.recordDataByRecordID.removeAll()
        self.importState = RobustImporter.ImportState.InPreparation
    }
    
    private func beginNotificationFetch(serverChangeToken: CKServerChangeToken? = nil) {
        
        // Create fetch notifications operation
        let fetchNotificationOperation = CKFetchNotificationChangesOperation(previousServerChangeToken: nil)
        fetchNotificationOperation.resultsLimit = 100
        
        // Set the per-notification block
        fetchNotificationOperation.notificationChangedBlock = self.handleNotificationFetched
        
        // Set the fetch completion block
        fetchNotificationOperation.fetchNotificationChangesCompletionBlock = { serverChangeToken, operationError in
            self.fetchNotificationsCompleted(fetchNotificationOperation.moreComing, serverChangeToken: serverChangeToken, operationError: operationError)
        }
        self.container.addOperation(fetchNotificationOperation)
    }
}

extension CloudNotificationProcessor : RobustImporterDelegate {
    func importDidFail(importer: RobustImporter) {
        print("importer did fail import with error: \(importer.importData.error)")
    }
    func importDidProgressState(importer: RobustImporter) {
        if importer.importData.state == RobustImporter.ImportState.AllDataDownloaded {
            importer.writeToCoredata()
            return
        }
        if self.isComplete() {
            dispatch_sync(self.queue) {
                self.isWorking = false
            }
            return
        }
    }
    
    private func writeToCoredata() {
        dispatch_sync(self.queue) {
            for (_,recordData) in self.recordDataByRecordID {
                if let importer = recordData.importer {
                    importer.writeToCoredata()
                }
            }
        }
    }
    private func isInErrorState() -> Bool {
        var result = true
        dispatch_sync(self.queue) {
            for (_,recordData) in self.recordDataByRecordID {
                guard let importer = recordData.importer else {
                    result = false
                    break
                }
                if importer.successRequired  && importer.isInErrorState() {
                    result = true
                    break
                }
            }
        }
        return result
    }
    private func isFullyDownloaded() -> Bool {
        var result = true
        dispatch_sync(self.queue) {
            for (_,recordData) in self.recordDataByRecordID {
                if recordData.isForeign { continue }
                guard let importer = recordData.importer else {
                    result = false
                    break
                }
                if importer.state() != RobustImporter.ImportState.AllDataDownloaded {
                    result = false
                }
            }
        }
        return result
    }
    
    private func isComplete() -> Bool {
        var result = true
        dispatch_sync(self.queue) {
            for (_,recordData) in self.recordDataByRecordID {
                if recordData.isForeign { continue }
                guard let importer = recordData.importer else {
                    result = false
                    break
                }
                if !importer.isComplete() || !importer.isInErrorState() {
                    result = false
                    break
                }
            }
        }
        return result
    }
}

extension CloudNotificationProcessor {
    
    
    private func importerForRecord(record:CKRecord) -> RobustImporter {
        return self.importerForRecordType(record.recordType, recordID: record.recordID)
    }
    
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

struct RecordData {
    var recordID:CKRecordID
    var record:CKRecord? = nil
    var notifications = Set<CKQueryNotification>()
    var isForeign = false
    var recordFetchError: NSError?
    var importer: RobustImporter?
    
    init(recordID:CKRecordID) {
        self.recordID = recordID
    }
    init(recordID:CKRecordID, record:CKRecord) {
        self.init(recordID: recordID)
        self.record = record
    }
}

extension CloudNotificationProcessor {
    
    private func handleNotificationFetched(notification: CKNotification) {
        // If the notification is a query type then add it to the array for future processing
        if notification.notificationType == .Query {
            let queryNotification = notification as! CKQueryNotification
            
            // Add the notification id to the array of processed notifications to mark them as read
            dispatch_sync(self.queue) {
                self.downloadedNotifications.append(queryNotification)
            }
        }
    }

    private func prepareRecordData() {
        dispatch_sync(self.queue) {
            self.recordDataByRecordID.removeAll()
            for notification in self.downloadedNotifications {
                if let recordID = notification.recordID {
                    var recordData = self.recordDataByRecordID[recordID] ?? RecordData(recordID: recordID)
                    recordData.notifications.insert(notification)
                    self.recordDataByRecordID[recordID] = recordData
                }
            }
        }
    }
    
    private var uniqueRecordIDs: [CKRecordID]  {
        let keys = self.recordDataByRecordID.keys
        return Array(keys)
    }
    
    private func handleFetchedRecord(record:CKRecord?, recordID: CKRecordID?, error: NSError?) {
        guard let recordID = recordID else {
            fatalError("Fetched record has no record ID") // Can this actually happen?
        }
        dispatch_sync(self.queue) {
            if let error = error {
                self.recordDataByRecordID[recordID]!.recordFetchError = error
            }
            if let record = record {
                self.recordDataByRecordID[recordID]!.record = record
                let belongsToSalon = self.recordBelongsToSalon(record)
                self.recordDataByRecordID[recordID]!.isForeign = !belongsToSalon
                if belongsToSalon {
                    let importer = self.importerForRecord(record)
                    self.recordDataByRecordID[recordID]!.importer = importer
                    importer.startImport(true)
                }
            }
        }
    }
    
    private func handleRecordFetchCompleted(recordInfo:[CKRecordID:CKRecord]?,error:NSError?) {
        if error != nil {
            // TODO: handle error
            print("error on handleRecordFetchCompleted: \(error)")
        }
        let foreignNotifications = self.foreignNotificationSubset()
        let processedNotifications = self.processedNotificationSubset()
        let markRead = foreignNotifications.union(processedNotifications)
        
        let readNotificationIDs = markRead.map { (notification) -> CKNotificationID in
            notification.notificationID!
        }
        
        let markOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: readNotificationIDs)
        markOperation.markNotificationsReadCompletionBlock = self.handleNotificationsMarkedRead
        self.container.addOperation(markOperation)
    }
    
    private func handleNotificationsMarkedRead(notificationIDsMarkedRead: [CKNotificationID]?, operationError: NSError?) {
        if operationError != nil {
            // TODO: Handle the error
            print("error on handleNotificationsMarkedRead: \(operationError)")
        }
    }

    private func foreignNotificationSubset() -> Set<CKQueryNotification> {
        var foreignNotifications = Set<CKQueryNotification>()
        for (_,recordData) in self.recordDataByRecordID {
            if recordData.isForeign {
                foreignNotifications.unionInPlace(recordData.notifications)
            }
        }
        return foreignNotifications
    }
    private func processedNotificationSubset() -> Set<CKQueryNotification> {
        var processedNotifications = Set<CKQueryNotification>()
        for (_,recordData) in self.recordDataByRecordID {
            if let importer = recordData.importer {
                if importer.isComplete() {
                    processedNotifications.unionInPlace(recordData.notifications)
                }
            }
        }
        return processedNotifications
    }
    
    private func processFetchedNotifications() {
        self.prepareRecordData()
        let recordFetchOp = CKFetchRecordsOperation(recordIDs: self.uniqueRecordIDs)
        recordFetchOp.perRecordCompletionBlock = self.handleFetchedRecord
        recordFetchOp.fetchRecordsCompletionBlock = self.handleRecordFetchCompleted
        
        // Execute the operation to fetch the records corresponding to the notifications
        self.container.publicCloudDatabase.addOperation(recordFetchOp)
    }
    
    private func fetchNotificationsCompleted(moreComing:Bool, serverChangeToken: CKServerChangeToken?, operationError: NSError?) {
        if operationError != nil {
            // TODO: Handle the error once we have worked out how
            print("Error on fetchNotificationsCompleted: \(operationError)")
        }

        // The previous operation might have returned only a subset of the missed notifications so now we check for more
        if moreComing {
            self.beginNotificationFetch(serverChangeToken)
            return
        }
        
        dispatch_sync(self.queue) {
            self.processFetchedNotifications()
        }
    }
}
