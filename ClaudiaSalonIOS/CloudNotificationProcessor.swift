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
    private var importState: ImportState = ImportState.InPreparation
    
    lazy var cloudSubscriber: CloudNotificationSubscriber = {
        return CloudNotificationSubscriber(database: self.publicCloudDatabase, cloudSalonRecordName: self.cloudSalonRecordName)
    }()

    private var downloadedNotifications = [CKQueryNotification]()
    private var recordDataByRecordID = [CKRecordID:RecordData]()
    private var notificationsToMarkRead = Set<CKQueryNotification>()
    
    
    class func parentSalonName(notification:CKNotification, salonRecordName:String) -> String? {
        guard notification.notificationType == .Query  else {
            return nil
        }
        guard let queryNotification = notification as? CKQueryNotification else {
            return nil
        }

        let salonReference = queryNotification.recordFields!["parentSalonReference"]
        return salonReference as? String
    }
    
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
        self.importState = ImportState.InPreparation
    }
    
    private func beginNotificationFetch(serverChangeToken: CKServerChangeToken? = nil) {
        
        // Create fetch notifications operation
        let fetchNotificationOperation = CKFetchNotificationChangesOperation(previousServerChangeToken: serverChangeToken)
        fetchNotificationOperation.resultsLimit = 100
        
        // Set the per-notification block
        fetchNotificationOperation.notificationChangedBlock = self.handleNotificationFetched
        
        // Set the fetch completion block
        fetchNotificationOperation.fetchNotificationChangesCompletionBlock = { serverChangeToken, operationError in
            self.fetchNotificationsCompleted(fetchNotificationOperation, serverChangeToken: serverChangeToken, operationError: operationError)
        }
        self.container.addOperation(fetchNotificationOperation)
    }
}

extension CloudNotificationProcessor : RobustImporterDelegate {
    func importDidFail(importer: RobustImporter) {
        print("importer did fail import with error: \(importer.importData.error)")
    }
    func importDidProgressState(importer: RobustImporter) {
        if importer.importData.state == ImportState.AllRequiredDataDownloaded {
            importer.writeToCoredata()
            return
        }
        // If this importer has completed then it is possible that we have completed too
        if importer.state().isComplete() || importer.state().isErrorState() {
            dispatch_sync(self.queue) {
                if self.isComplete() {
                    self.isWorking = false
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
                if importer.successRequired  && importer.state().isErrorState() {
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
                if importer.state() != ImportState.AllRequiredDataDownloaded {
                    result = false
                }
            }
        }
        return result
    }
    
    private func isComplete() -> Bool {
        var result = true
        for (_,recordData) in self.recordDataByRecordID {
            if recordData.isForeign { continue }
            guard let importer = recordData.importer else {
                result = false
                break
            }
            if !importer.state().isComplete() || !importer.state().isErrorState() {
                result = false
                break
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
            return SalonImporter(key: "salon", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, record:nil , successRequired: true, delegate: self)
        case .Customer:
            return CustomerImporter(key: "customer", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, record:nil , successRequired: true, delegate: self)
        case .Employee:
            return EmployeeImporter(key: "employee", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, record:nil , successRequired: true, delegate: self)
        case .ServiceCategory:
            return ServiceCategoryImporter(key: "serviceCategory", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, record:nil , successRequired: true, delegate: self)
        case .Service:
            return ServiceImporter(key: "service", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, record:nil , successRequired: true, delegate: self)
        case .Appointment:
            return AppointmentImporter(key: "appointment", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, record:nil , successRequired: true, delegate: self)
        case .Sale:
            return SaleImporter(key: "sale", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, record:nil , successRequired: true, delegate: self)
        case .SaleItem:
            return SaleItemImporter(key: "saleItem", moc: self.moc, cloudDatabase: self.publicCloudDatabase, recordID: recordID, record:nil , successRequired: true, delegate: self)
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

    private func prepareRecordData(notificationsToProcess:[CKQueryNotification]) {
        self.recordDataByRecordID.removeAll()
        for notification in notificationsToProcess {
            if let recordID = notification.recordID {
                var recordData = self.recordDataByRecordID[recordID] ?? RecordData(recordID: recordID)
                recordData.notifications.insert(notification)
                recordData.isForeign = self.isNotificationDefinitelyForeign(notification)
                self.recordDataByRecordID[recordID] = recordData
            }
        }
    }
    private func isNotificationDefinitelyForeign(queryNotification:CKQueryNotification) -> Bool {
        if let parentSalonRecordName = queryNotification.recordFields?["parentSalonReference"] as? String {
            if parentSalonRecordName != self.cloudSalonRecordName {
                return true
            }
        }
        return false  // Can't tell because notification didn't provide enough info
    }
    
    private var uniqueRecordIDs: [CKRecordID]  {
        let keys = self.recordDataByRecordID.keys
        return Array(keys)
    }
    private var uniqueRecordIDsToProcess: [CKRecordID] {
        let ownedRecordIDs = self.recordDataByRecordID.filter { (recordID, recordData) -> Bool in
            !recordData.isForeign
        }
        return ownedRecordIDs.map { (recordID, recordData) -> CKRecordID in
            recordID
        }
    }
    
    private func handleFetchedRecord(record:CKRecord?, recordID: CKRecordID?, error: NSError?) {
        let recordID = recordID!
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
                    importer.startImport()
                }
            }
        }
    }
    
    private func handleRecordFetchCompleted(fetchOperation:CKFetchRecordsOperation,recordInfo:[CKRecordID:CKRecord]?,error:NSError?) {
        if let error = error {
            if error.code == CKErrorCode.LimitExceeded.rawValue {
                let recordsWanted = fetchOperation.recordIDs!
                let n = recordsWanted.count / 2
                let arrays = recordsWanted.subdivideAtIndex(n)
                let operation1 = self.makeFetchRecordsOperation(arrays.left)
                let operation2 = self.makeFetchRecordsOperation(arrays.right)
                operation2.addDependency(operation1)
                self.publicCloudDatabase.addOperation(operation1)
                self.publicCloudDatabase.addOperation(operation2)
                return
            } else {
                print("error on handleRecordFetchCompleted: \(error)")
            }
        }
        let foreignNotifications = self.foreignNotificationSubset()
        let processedNotifications = self.processedNotificationSubset()
        let markRead = foreignNotifications.union(processedNotifications)
        
        let readNotificationIDs = markRead.map { (notification) -> CKNotificationID in
            notification.notificationID!
        }
        
        let markOperation = self.makeMarkNotificationsAsReadOperation(readNotificationIDs)
        self.container.addOperation(markOperation)
    }
    
    private func makeMarkNotificationsAsReadOperation(readNotificationIDs:[CKNotificationID]) -> CKMarkNotificationsReadOperation {
        let markOperation = CKMarkNotificationsReadOperation(notificationIDsToMarkRead: readNotificationIDs)
        markOperation.markNotificationsReadCompletionBlock = { notifcationIDsMarkedRead, operationError in
            self.handleNotificationsMarkedRead(markOperation, notificationIDsMarkedRead: notifcationIDsMarkedRead, operationError: operationError)
        }
        return markOperation
    }
    
    private func handleNotificationsMarkedRead(markOperation:CKMarkNotificationsReadOperation,notificationIDsMarkedRead: [CKNotificationID]?, operationError: NSError?) {
        if let error = operationError {
            if error.code == CKErrorCode.LimitExceeded.rawValue {
                let notifications = markOperation.notificationIDs
                let n = notifications.count / 2
                let arrays = notifications.subdivideAtIndex(n)
                let operation1 = self.makeMarkNotificationsAsReadOperation(arrays.left)
                let operation2 = self.makeMarkNotificationsAsReadOperation(arrays.right)
                operation2.addDependency(operation1)
                self.container.addOperation(operation1)
                self.container.addOperation(operation2)
                return
            } else {
                assertionFailure("error on handleNotificationsMarkedRead: \(operationError)")
                return
            }
        }
        if let numberMarkedRead = notificationIDsMarkedRead?.count where notificationIDsMarkedRead?.count > 0 {
            print("\(numberMarkedRead) cloud notifications were successfully marked as read")
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
                if importer.state().isComplete() {
                    processedNotifications.unionInPlace(recordData.notifications)
                }
            }
        }
        return processedNotifications
    }
    
    private func makeFetchRecordsOperation(recordIDs:[CKRecordID]) -> CKFetchRecordsOperation {
        let recordFetchOp = CKFetchRecordsOperation(recordIDs: recordIDs)
        
        recordFetchOp.perRecordCompletionBlock = self.handleFetchedRecord
        recordFetchOp.fetchRecordsCompletionBlock = { recordInfo, error in
            self.handleRecordFetchCompleted(recordFetchOp,recordInfo: recordInfo, error:error)
        }
        return recordFetchOp
    }
    
    private func fetchNotificationsCompleted(fetchNotificationsOperation:CKFetchNotificationChangesOperation, serverChangeToken: CKServerChangeToken?, operationError: NSError?) {
        if operationError != nil {
            // TODO: Handle the error once we have worked out how
            print("Error on fetchNotificationsCompleted: \(operationError)")
        }

        // The previous operation might have returned only a subset of the missed notifications so now we check for more
        if fetchNotificationsOperation.moreComing {
            self.beginNotificationFetch(serverChangeToken)
            return
        }
        
        dispatch_sync(self.queue) {
            // Reject foreign notifications and mark them as read
            let processFilter = self.rejectOrProcessFilter()
            if processFilter.reject.count > 0 {
                let markOperation = self.makeMarkNotificationsAsReadOperation(processFilter.reject)
                self.container.addOperation(markOperation)
            }
            // Process notifications intended for the current salon
            self.prepareRecordData(processFilter.notificationsToProcess)
            let recordsToProcess = self.uniqueRecordIDsToProcess
            if recordsToProcess.count > 0 {
                let recordFetchOp = self.makeFetchRecordsOperation(self.uniqueRecordIDsToProcess)
                self.container.publicCloudDatabase.addOperation(recordFetchOp)
            } else {
                self.isWorking = false
            }
        }
    }
    private func rejectOrProcessFilter() -> (reject:[CKNotificationID],notificationsToProcess:[CKQueryNotification]) {
        var reject = [CKNotificationID]()
        var process = [CKQueryNotification]()
        for notification in self.downloadedNotifications {
            let notificationID = notification.notificationID!
            if self.isNotificationDefinitelyForeign(notification) {
                reject.append(notificationID)
            } else {
                process.append(notification)
            }
        }
        return (reject,process)
    }
}
