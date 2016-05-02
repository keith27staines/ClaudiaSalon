//
//  RobustDownloader.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 02/05/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

class RobustImporter : RobustImporterDelegate {
    // API properties
    private (set) var recordType: ICloudRecordType?
    private (set) var importData:ImportData

    // Implementation properties
    private let moc:NSManagedObjectContext
    private let cloudDatabase:CKDatabase
    private weak var delegate: RobustImporterDelegate!
    private var selfReference:CKReference? {
        let selfRecord = self.importData.cloudRecord!
        return CKReference(record: selfRecord, action: .None)
    }
    
    private lazy var synchQueue:NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.name = "RobustImportQueue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    // Initializers
    private init(moc:NSManagedObjectContext, cloudDatabase:CKDatabase, recordType:ICloudRecordType, recordID:CKRecordID, delegate:RobustImporterDelegate) {
        self.moc = moc
        self.cloudDatabase = cloudDatabase
        self.recordType = recordType
        self.importData = ImportData(recordType:recordType,
                                     recordID: recordID,
                                     coredataID: nil,
                                     cloudRecord: nil,
                                     coredataRecord: nil,
                                     error: nil,
                                     state: .InPreparation)
    }
    
    // API methods
    func startImport() -> Bool {
        guard self.importData.state == .InPreparation else {
            return false
        }
        self.changeState(.DownloadingRecord)
        let recordID = self.importData.recordID!
        self.cloudDatabase.fetchRecordWithID(recordID, completionHandler: self.handleFetchedPrimaryRecord)
        return true
    }
    
    // Override this method if necessary, but call super to automatically take care of state changes and notifications.
    // Note that the implementation of this function is martialled onto the synchronization queue
    private func handleFetchedPrimaryRecord(record:CKRecord?, nsError:NSError?) {
        self.synchQueue.addOperationWithBlock() {
            if let nsError = nsError {
                let error = self.translateNSError(nsError)
                self.importData.error = error
                self.changeStateForError(error)
                return
            }
            if let record = record {
                self.importData.cloudRecord = record
                self.changeState(.DownloadingChildRecords)
                self.startDownloadingChildRecords()
            }
        }
    }
    
    // Override if the subclass has child records
    func startDownloadingChildRecords() {
        // Default implementation doesn't trigger download of children and changes state to download complete
        self.changeState(.AllDataDownloaded)
    }
    
    // MUST OVERRIDE
    func writeToCoredata() {
        self.save()
    }
    
    func save() {
        self.moc.performBlockAndWait() {
            guard self.moc.hasChanges else {
                return
            }
            do {
                try self.moc.save()
                self.changeState(.Complete)
            } catch let nsError as NSError {
                self.changeStateForError(nsError)
            }
        }
    }
    
    func importDidFail(importer: RobustImporter, error: RobustImporter.ImportError) {
        self.delegate.importDidFail(self, error: error)
    }
    
    func importDidProgressState(importer: RobustImporter, importData: ImportData) {
        
    }
}

protocol RobustImporterDelegate : class {
    func importDidFail(importer:RobustImporter, error:RobustImporter.ImportError)
    func importDidProgressState(importer:RobustImporter,importData:RobustImporter.ImportData)
}

extension RobustImporter {
    // Implementation methods
    
    private func changeState(newState:ImportState) {
        self.synchQueue.addOperationWithBlock() {
            assert(newState != .InvalidState, "The import has entered and invalid state")
            guard self.importData.state != .InvalidState else {
                fatalError("An import in an invalid state has been further processed")
            }
            self.importData.state = newState
            self.delegate?.importDidProgressState(self, importData: self.importData)
        }
    }
    
    private func changeStateForError(nsError:NSError) {
        let error = self.translateNSError(nsError)
        self.changeStateForError(error)
    }
    private func changeStateForError(error:ImportError) {
        self.synchQueue.addOperationWithBlock() {
            self.importData.error = error
            switch self.importData.state {
                
            // Active states can legitimately be failed
            case ImportState.DownloadingRecord:
                self.changeState(.FailedToDownloadRecord)
                
            case ImportState.DownloadingChildRecords:
                self.changeState(.FailedToDownloadRequiredChild)
                
            case ImportState.WritingToCoredata:
                self.changeState(.FailedToWriteToCoredata)
                
            // Inactive states should never suffer a failure since they aren't doing anything
            case ImportState.InPreparation,
                 ImportState.AllDataDownloaded,
                 ImportState.Complete,
                 ImportState.InvalidState:
                assertionFailure("Trying to set an error when currently inactive")
                self.changeState(.InvalidState)
                
            // Failed states should never suffer a further failure
            case ImportState.FailedToDownloadRecord,
                 ImportState.FailedToDownloadRequiredChild,
                 ImportState.FailedToWriteToCoredata:
                assertionFailure("Trying to set an error when already in an error state")
            }
            self.delegate.importDidFail(self, error: error)
        }
    }
    
    private func translateNSError(nsError:NSError) -> ImportError {
        switch self.importData.state {
            
        // Active states can legitimately be failed
        case ImportState.DownloadingRecord:
            return ImportError.CloudError(nsError)
            
        case ImportState.DownloadingChildRecords:
            return ImportError.CloudError(nsError)
            
        case ImportState.WritingToCoredata:
            return ImportError.CoredataError(nsError)
            
        // Inactive states should never suffer a failure since they aren't doing anything
        case ImportState.InPreparation,
             ImportState.AllDataDownloaded,
             ImportState.Complete:
            return ImportError.UnknownError(nsError)
            
        // Failed states should never suffer a further failure
        case ImportState.FailedToDownloadRecord,
             ImportState.FailedToDownloadRequiredChild,
             ImportState.FailedToWriteToCoredata:
             return self.importData.error ?? ImportError.UnknownError(nsError)
        
        // If we are in an invalid state then the situation is already horribly confused
        case ImportState.InvalidState:
            return self.importData.error ?? ImportError.UnknownError(nsError)
        }
    }
}

extension RobustImporter {
    enum ImportError : ErrorType {
        case CloudRecordNotFound
        case CloudError(NSError?)
        case ChildRecordNotFound
        case CoredataError(NSError?)
        case UnknownError(NSError?)
    }
    
    enum ImportState {
        case InPreparation
        case DownloadingRecord
        case FailedToDownloadRecord
        case DownloadingChildRecords
        case FailedToDownloadRequiredChild
        case AllDataDownloaded
        case WritingToCoredata
        case FailedToWriteToCoredata
        case Complete
        case InvalidState
    }
    
    struct ImportData {
        var recordType: ICloudRecordType?
        var recordID: CKRecordID?
        var coredataID: String?
        var cloudRecord: CKRecord?
        var coredataRecord: NSManagedObject?
        var error: ImportError?
        var state: ImportState
    }
}

class AppointmentImporter : RobustImporter {
    
    private var saleImporter: SaleImporter?
    
    var childImportData = [ICloudRecordType:ImportData]()
    
    init(moc: NSManagedObjectContext, cloudDatabase: CKDatabase, recordID: CKRecordID, delegate: RobustImporterDelegate) {
        let recordType = ICloudRecordType.Appointment
        super.init(moc:moc, cloudDatabase:cloudDatabase, recordType:recordType, recordID:recordID, delegate:delegate)
    }
    
    override func startDownloadingChildRecords() {
        let childRecordTypes = [ICloudRecordType.Customer, ICloudRecordType.Sale]
        self.childImportData.removeAll()
        for recordType in childRecordTypes {
            self.childImportData[recordType] = ImportData(recordType: recordType, recordID: nil, coredataID: nil, cloudRecord: nil, coredataRecord: nil, error: nil, state: .InPreparation)
        }
        super.startDownloadingChildRecords()
        self.startRetrievingCustomer()
    }
    
    override func importDidFail(importer: RobustImporter, error: RobustImporter.ImportError) {
        self.changeStateForError(error)
    }
    
    override func importDidProgressState(importer: RobustImporter, importData: ImportData) {
        if importData.state == .Complete {
            self.changeState(.AllDataDownloaded)
        }
    }
    
    override func writeToCoredata() {
        self.moc.performBlockAndWait() {
            
        }
        super.writeToCoredata()
    }
}

extension AppointmentImporter {
    private func startRetrievingCustomer() {
        let appointmentRecord = self.importData.cloudRecord!
        let customerReference = appointmentRecord["customerReference"] as! CKReference
        self.cloudDatabase.fetchRecordWithID(customerReference.recordID , completionHandler: self.fetchCustomerCompleted)
    }
    private func fetchCustomerCompleted(customerRecord:CKRecord?, error:NSError?) {
        if let error = error {
            // Generate error state because Customers are a required property for appointments
            self.changeStateForError(error)
            return
        }
        self.startRetrievingSale()
    }
}
extension AppointmentImporter {
    private func startRetrievingSale() {
        let predicate = NSPredicate(format: "parentAppointmentReference = %@", self.selfReference!)
        let query = CKQuery(recordType: ICloudRecordType.Sale.rawValue , predicate: predicate)
        let queryOp = CKQueryOperation(query: query)
        queryOp.queryCompletionBlock = self.handleSaleQueryCompletion
        queryOp.recordFetchedBlock = self.handleSaleRecordFetched
        self.cloudDatabase.addOperation(queryOp)
    }
    private func handleSaleRecordFetched(saleRecord:CKRecord) {
        self.synchQueue.addOperationWithBlock() {
            self.childImportData[ICloudRecordType.Sale]?.cloudRecord = saleRecord
            self.childImportData[ICloudRecordType.Sale]?.recordID = saleRecord.recordID
        }
    }
    private func handleSaleQueryCompletion(cursor:CKQueryCursor?, error:NSError?) {
        if let error = error {
            self.changeStateForError(error)
            return
        }
        if let _ = cursor {
            let error = ImportError.CloudError(nil)
            self.changeStateForError(error)
            return
        }
        guard let saleRecord = self.childImportData[ICloudRecordType.Sale]?.cloudRecord else {
            let error = ImportError.CloudError(nil)
            self.changeStateForError(error)
            return
        }
        self.saleImporter = SaleImporter(moc: self.moc, cloudDatabase: self.cloudDatabase, recordID: saleRecord.recordID, delegate: self.delegate)
        self.saleImporter!.startImport()
    }
}

//////////////////////////////////


class SaleImporter : RobustImporter {
    
    var childImportData = [ICloudRecordType:ImportData]()
    
    init(moc: NSManagedObjectContext, cloudDatabase: CKDatabase, recordID: CKRecordID, delegate: RobustImporterDelegate) {
        let recordType = ICloudRecordType.Sale
        super.init(moc:moc, cloudDatabase:cloudDatabase, recordType:recordType, recordID:recordID, delegate:delegate)
    }
    
    override func startDownloadingChildRecords() {
        let childRecordTypes = [ICloudRecordType.Customer, ICloudRecordType.Sale]
        self.childImportData.removeAll()
        for recordType in childRecordTypes {
            self.childImportData[recordType] = ImportData(recordType: recordType, recordID: nil, coredataID: nil, cloudRecord: nil, coredataRecord: nil, error: nil, state: .InPreparation)
        }
        super.startDownloadingChildRecords()
        self.startRetrievingCustomer()
    }
    
    override func writeToCoredata() {
        self.moc.performBlockAndWait() {
            
        }
        super.writeToCoredata()
    }
}

extension SaleImporter {
    private func startRetrievingCustomer() {
        let appointmentRecord = self.importData.cloudRecord!
        let customerReference = appointmentRecord["customerReference"] as! CKReference
        self.cloudDatabase.fetchRecordWithID(customerReference.recordID , completionHandler: self.fetchCustomerCompleted)
    }
    private func fetchCustomerCompleted(customerRecord:CKRecord?, error:NSError?) {
        if let error = error {
            // Generate error state because Customers are a required property for appointments
            self.changeStateForError(error)
            return
        }
        self.startRetrievingSale()
    }
}
extension SaleImporter {
    private func startRetrievingSale() {
        let predicate = NSPredicate(format: "parentAppointmentReference = %@", self.selfReference!)
        let query = CKQuery(recordType: ICloudRecordType.Sale.rawValue , predicate: predicate)
        let queryOp = CKQueryOperation(query: query)
        queryOp.queryCompletionBlock = self.saleOperationCompleted
        queryOp.recordFetchedBlock = self.saleRecordFetched
        self.cloudDatabase.addOperation(queryOp)
    }
    private func saleRecordFetched(saleRecord:CKRecord) {
        self.synchQueue.addOperationWithBlock() {
            self.childImportData[ICloudRecordType.Sale]?.cloudRecord = saleRecord
            self.childImportData[ICloudRecordType.Sale]?.recordID = saleRecord.recordID
        }
    }
    private func saleOperationCompleted(cursor:CKQueryCursor?, error:NSError?) {
        if let error = error {
            self.changeStateForError(error)
            return
        }
        if let _ = cursor {
            let error = ImportError.CloudError(nil)
            self.changeStateForError(error)
            return
        }
        guard let _ = self.childImportData[ICloudRecordType.Sale]?.cloudRecord else {
            let error = ImportError.CloudError(nil)
            self.changeStateForError(error)
            return
        }
        self.changeState(.AllDataDownloaded)
    }
}


