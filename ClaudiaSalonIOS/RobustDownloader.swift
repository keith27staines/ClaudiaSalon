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

////////////////////////////////////////////
// MARK:- RobustImporter delegate protocol -
protocol RobustImporterDelegate : class {
    func importDidFail(importer:RobustImporter)
    func importDidProgressState(importer:RobustImporter)
}

//////////////////////////////////////
// MARK:- RobustImporter  base class -
class RobustImporter : RobustImporterDelegate {

    // MARK - Subclasses should set this property in their initializers
    private (set) var recordType:ICloudRecordType!
    
    // MARK: - API properties
    private (set) var key: String
    private (set) var recordID: CKRecordID!
    private (set) var importData:ImportData
    private (set) var childImporters = [String:RobustImporter]()
    private (set) var successRequired = false

    // MARK:- Implementation properties
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
    
    
    // MARK: - Initializers
    // Initializer - do not call this from subclasses
    private init(key:String, moc:NSManagedObjectContext, cloudDatabase:CKDatabase, recordType:ICloudRecordType, recordID:CKRecordID, delegate:RobustImporterDelegate) {
        self.key = key
        self.moc = moc
        self.cloudDatabase = cloudDatabase
        self.recordType = recordType
        self.recordID = recordID
        self.delegate = delegate
        self.childImporters = [String:RobustImporter]()
        self.importData = ImportData(recordType:self.recordType,
                                     recordID: self.recordID,
                                     coredataID: nil,
                                     cloudRecord: nil,
                                     coredataRecord: nil,
                                     error: nil,
                                     state: .InPreparation)
    }
    
    required init(key:String, moc:NSManagedObjectContext, cloudDatabase:CKDatabase, recordID:CKRecordID, delegate:RobustImporterDelegate) {
        fatalError("Subclasses must override this method")
    }
    
    // MARK:- API methods
    func startImport(successRequired:Bool) -> Bool {
        guard self.importData.state == .InPreparation else {
            return false
        }
        self.successRequired = successRequired
        self.childImporters = [String:RobustImporter]()
        self.importData = ImportData(recordType:self.recordType,
                                     recordID: self.recordID,
                                     coredataID: nil,
                                     cloudRecord: nil,
                                     coredataRecord: nil,
                                     error: nil,
                                     state: .InPreparation)

        self.changeState(.DownloadingRecord)
        self.cloudDatabase.fetchRecordWithID(self.recordID, completionHandler: self.handleFetchedPrimaryRecord)
        return true
    }
    
    func state() -> ImportState {
        return self.importData.state
    }
    
    func isInErrorState() -> Bool {
        let state = self.importData.state
        switch state {
        case .FailedToDownloadRecord,
             .FailedToDownloadRequiredChild,
             .FailedToWriteToCoredata,
             .InvalidState:
            return true
        default:
            return false
        }
    }
    
    func isComplete() -> Bool {
        let state = self.importData.state
        return state == ImportState.Complete
    }
    
    func isWorking() -> Bool {
        if self.isComplete() { return false }
        if self.importData.state == ImportState.InPreparation { return false }
        if self.isInErrorState() { return false }
        return true
    }
    
    // MARK:- Methods that may be overridden
    
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
        // Base implementation doesn't trigger download of children and changes state to download complete
        self.childImporters.removeAll()
        self.changeState(.AllDataDownloaded)
    }
    
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
    
    // MARK: - RobustDownloader delegate implementation
    func importDidFail(importer: RobustImporter) {
        guard let error = importer.importData.error else {
            preconditionFailure("Error was not set on an importer reporting a failure")
        }
        switch error {
        case ImportError.CloudError(let nsErr):
            let higherError = ImportError.ChildRecordFailure(nsErr)
            self.changeStateForError(higherError)
            break
        default:
            self.changeStateForError(error)
        }
    }
    
    func importDidProgressState(importer: RobustImporter) {
        // If our child imports are all complete, then we are complete. If any one of them isn't complete, then neither are we
        for (_,importer) in self.childImporters {
            guard importer.importData.state == ImportState.AllDataDownloaded else {
                // This child hasb't downloaded, so neither have we
                return
            }
        }
        // All child imports downloaded, so we have also completed downloading
        self.changeState(.Complete)
    }
    
    private func handleFetchedChildObjectID(childRecord:CKRecord) {
        fatalError("Sublcasses must override this method")
    }
    
    private func handleFetchChildrenDidComplete(error:NSError?) {
        if let error = error {
            let error = self.translateNSError(error)
            self.changeStateForError(error)
        }
    }

}

extension RobustImporter {
    func makeMainRecordQueryOperation(recordyType:String, predicate:NSPredicate, recordFetchBlock:(CKRecord,NSError)->Void, queryCompletionBlock:([CKRecord],NSError)) {
        let query = CKQuery(recordType: recordyType, predicate: predicate)
        let fetchOperation = CKQueryOperation(query: query)
        fetchOperation.queryCompletionBlock = { cursor, error in

        }
        fetchOperation.recordFetchedBlock = { record in
            
        }
        self.cloudDatabase.addOperation(fetchOperation)
    }
}

extension RobustImporter {
    // MARK:- State management
    
    private func changeState(newState:ImportState) {
        self.synchQueue.addOperationWithBlock() {
            assert(newState != .InvalidState, "The import has entered and invalid state")
            guard self.importData.state != .InvalidState else {
                fatalError("An import in an invalid state has been further processed")
            }
            self.importData.state = newState
            self.delegate?.importDidProgressState(self)
        }
    }
    
    private func changeStateForError(nsError:NSError) {
        let error = self.translateNSError(nsError)
        self.changeStateForError(error)
    }
    private func changeStateForError(error:ImportError) {
        self.synchQueue.addOperationWithBlock() {
            guard self.successRequired else {
                // If success isn't required then we have finished processing (simply because errors prevent us continuing), so we mark ourselves complete
                self.importData.error = error
                self.changeState(.Complete)
                return
            }
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
            self.delegate.importDidFail(self)
        }
    }

    // MARK: - Convenience methods
    func addChildImporter(importer:RobustImporter) {
        let key = importer.key
        self.childImporters[key] = importer
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

/////////////////////////////////
// MARK: - Fetching child records
extension RobustImporter {
    private var referenceFieldNameForChildren:String {
        let recordType = self.recordType!
        let cloudRecordType = CloudRecordType(rawValue: recordType.rawValue)
        let entityName = CloudRecordType.coredataEntityNameForType(cloudRecordType!)
        let fieldname = "parent" + entityName + "Reference"
        return fieldname
    }
    private func makeFetchChildRecordsOperation(childRecordType:ICloudRecordType) -> CKQueryOperation {
        let predicate = NSPredicate(format: "\(self.referenceFieldNameForChildren) = %@", self.selfReference!)
        let query = CKQuery(recordType: childRecordType.rawValue, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        self.finishPreparingFetchChildOperation(queryOperation)
        return queryOperation
    }
    
    private func makeFetchChildRecordOperation(cursor:CKQueryCursor) -> CKQueryOperation {
        let queryOperation = CKQueryOperation(cursor: cursor)
        self.finishPreparingFetchChildOperation(queryOperation)
        return queryOperation
    }
    
    private func finishPreparingFetchChildOperation(queryOperation:CKQueryOperation) {
        queryOperation.name = "fetchChildOperation"
        queryOperation.queryCompletionBlock = { cursor, error in
            if let error = error {
                let e = self.translateNSError(error)
                self.changeStateForError(e)
                return
            }
            if let cursor = cursor {
                self.cloudDatabase.addOperation(self.makeFetchChildRecordOperation(cursor))
                return
            }
        }
    }
}

extension RobustImporter {
    // MARK: - Error type enumeration
    enum ImportError : ErrorType {
        case CloudRecordNotFound(NSError?)
        case CloudError(NSError?)
        case ChildRecordFailure(NSError?)
        case CoredataError(NSError?)
        case UnknownError(NSError?)
    }
    
    // MARK: - ImportState enumeration
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
    
    // MARK: - ImportData Struct
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

////////////////////////////////////////////////
// MARK:- AppointmentImporter (RobustImporter sublcass) -
class AppointmentImporter : RobustImporter {
    
    // Child importers
    private let customerKey = "parentCustomerReference"
    private var customerRecordID:CKRecordID!
    private var customerImporter: CustomerImporter?

    // Associated object importers
    private let saleKey = "sale"
    private var saleRecordID:CKRecordID!
    private var saleImporter: SaleImporter?

    required init(key:String, moc: NSManagedObjectContext,
         cloudDatabase: CKDatabase,
         recordID: CKRecordID,
         delegate: RobustImporterDelegate) {
        
        let recordType = ICloudRecordType.Appointment
        super.init(key:key, moc:moc, cloudDatabase:cloudDatabase, recordType:recordType, recordID:recordID, delegate:delegate)
    }
    
    private override func handleFetchedPrimaryRecord(record: CKRecord?, nsError: NSError?) {
        if let record = record {
            let customerReference = record[customerKey] as! CKReference
            self.customerRecordID = customerReference.recordID
        }
        super.handleFetchedPrimaryRecord(record, nsError: nsError)
    }
    
    override func startDownloadingChildRecords() {
        super.startDownloadingChildRecords()
        self.startDownloadingCustomer()
    }
    
    override func importDidProgressState(importer: RobustImporter) {
        if importer.key == self.customerKey  && importer.isComplete() {
            self.startDownloadingSale()
            return
        }
        super.importDidProgressState(importer)
    }
    
    override func writeToCoredata() {
        self.moc.performBlockAndWait() {
            
        }
        super.writeToCoredata()
        
    }

    private func startDownloadingCustomer() {
        let customerImporter = CustomerImporter(key: self.customerKey, moc: self.moc, cloudDatabase: self.cloudDatabase, recordID: self.customerRecordID, delegate: self)
        self.addChildImporter(customerImporter)
        self.customerImporter?.startImport(true)
    }
    private func startDownloadingSale() {
        self.saleRecordID = nil
        let queryop = self.makeFetchChildRecordsOperation(ICloudRecordType.Sale)
        self.cloudDatabase.addOperation(queryop)
    }
    
    override private func handleFetchedChildObjectID(childRecord: CKRecord) {
        assert(self.saleRecordID == nil, "This appointment's saleRecordID was already set - are there two or more sales for this appointment?")
        self.saleRecordID = childRecord.recordID
    }
    
    override func handleFetchChildrenDidComplete(error: NSError?) {
        super.handleFetchChildrenDidComplete(error)
        if let saleRecordID = self.saleRecordID {
            // We have the saleID so go ahead and use a SaleImporter to completely download the sale
            let saleImporter = SaleImporter(key: self.saleKey, moc: self.moc, cloudDatabase: self.cloudDatabase, recordID: saleRecordID, delegate: self)
            self.addChildImporter(saleImporter)
            self.saleImporter?.startImport(true)
        }
    }
}

//////////////////////////////////////////////////////
// MARK:- CustomerImporter (RobustImporter sublcass) -
class CustomerImporter : RobustImporter {
    
    required init(key:String, moc: NSManagedObjectContext,
                  cloudDatabase: CKDatabase,
                  recordID: CKRecordID,
                  delegate: RobustImporterDelegate) {
        
        let recordType = ICloudRecordType.Customer
        super.init(key:key, moc:moc, cloudDatabase:cloudDatabase, recordType:recordType, recordID:recordID, delegate:delegate)
    }
    
    override func writeToCoredata() {
        self.moc.performBlockAndWait() {
            
        }
        super.writeToCoredata()
    }
}

//////////////////////////////////////////////////////
// MARK:- SaleImporter (RobustImporter sublcass) -
class SaleImporter : RobustImporter {
    private let customerKey = "customer"
    private var customerRecordID:CKRecordID!
    private var customerImporter: CustomerImporter?
    
    private let saleItemKey = "saleItem"
    private var saleItemImporters = [SaleItemImporter]()
    
    required init(key:String, moc: NSManagedObjectContext,
                  cloudDatabase: CKDatabase,
                  recordID: CKRecordID,
                  delegate: RobustImporterDelegate) {
        
        let recordType = ICloudRecordType.Sale
        super.init(key:key, moc:moc, cloudDatabase:cloudDatabase, recordType:recordType, recordID:recordID, delegate:delegate)
    }
    
    private override func handleFetchedPrimaryRecord(record: CKRecord?, nsError: NSError?) {
        if let record = record {
            let customerReference = record["customerReference"] as! CKReference
            self.customerRecordID = customerReference.recordID
        }
        super.handleFetchedPrimaryRecord(record, nsError: nsError)
    }
    
    override func startDownloadingChildRecords() {
        super.startDownloadingChildRecords()
        self.startDownloadingCustomer()
    }
    
    override func importDidProgressState(importer: RobustImporter) {
        if importer.key == self.customerKey  && importer.isComplete() {
            self.startDownloadingSaleItems()
            return
        }
        super.importDidProgressState(importer)
    }
    
    override func writeToCoredata() {
        self.moc.performBlockAndWait() {
            
        }
        super.writeToCoredata()
    }

    override func handleFetchedChildObjectID(childRecord: CKRecord) {
        if childRecord.recordType == ICloudRecordType.SaleItem.rawValue {
            let saleItemImporter = SaleItemImporter(key: self.saleItemKey, moc: self.moc, cloudDatabase: self.cloudDatabase, recordID: childRecord.recordID, delegate: self)
            self.saleItemImporters.append(saleItemImporter)
        }
    }
    
    override func handleFetchChildrenDidComplete(error: NSError?) {
            super.handleFetchChildrenDidComplete(error)
        if self.isWorking() {
            for importer in self.saleItemImporters {
                importer.startImport(true)
            }
        }
    }

}

extension SaleImporter {
    private func startDownloadingCustomer() {
        let customerImporter = CustomerImporter(key: self.customerKey, moc: self.moc, cloudDatabase: self.cloudDatabase, recordID: self.customerRecordID, delegate: self)
        self.addChildImporter(customerImporter)
        self.customerImporter?.startImport(true)
    }
    private func startDownloadingSaleItems() {
        self.saleItemImporters.removeAll()
        let queryOp = self.makeFetchChildRecordsOperation(ICloudRecordType.SaleItem)
        self.cloudDatabase.addOperation(queryOp)
    }
}

//////////////////////////////////////////////////////
// MARK:- SaleItemImporter (RobustImporter sublcass) -
class SaleItemImporter : RobustImporter {
    private let serviceKey = "service"
    private var serviceRecordID:CKRecordID!
    private var serviceImporter: ServiceImporter?
    
    private let employeeKey = "stylist"
    private var employeeRecordID: CKRecordID!
    private var employeeImporter: EmployeeImporter?
    
    required init(key:String, moc: NSManagedObjectContext,
                  cloudDatabase: CKDatabase,
                  recordID: CKRecordID,
                  delegate: RobustImporterDelegate) {
        
        let recordType = ICloudRecordType.SaleItem
        super.init(key:key, moc:moc, cloudDatabase:cloudDatabase, recordType:recordType, recordID:recordID, delegate:delegate)
    }
    
    private override func handleFetchedPrimaryRecord(record: CKRecord?, nsError: NSError?) {
        if let record = record {
            let customerReference = record["serviceReference"] as! CKReference
            self.serviceRecordID = customerReference.recordID
            let employeeReference = record["employeeReference"] as! CKReference
            self.employeeRecordID = employeeReference.recordID
        }
        super.handleFetchedPrimaryRecord(record, nsError: nsError)
    }
    
    override func startDownloadingChildRecords() {
        super.startDownloadingChildRecords()
        self.serviceImporter = ServiceImporter(key: self.serviceKey, moc: self.moc, cloudDatabase: self.cloudDatabase, recordID: self.serviceRecordID, delegate: self)
        self.employeeImporter = EmployeeImporter(key: self.employeeKey, moc: self.moc, cloudDatabase: self.cloudDatabase, recordID: self.employeeRecordID, delegate: self)
        self.addChildImporter(self.serviceImporter!)
        self.addChildImporter(self.employeeImporter!)
        self.serviceImporter?.startImport(true)
    }
    
    override func importDidProgressState(importer: RobustImporter) {
        if importer.key == self.serviceKey  && importer.isComplete() {
            self.employeeImporter?.startImport(true)
            return
        }
        super.importDidProgressState(importer)
    }
    
    override func writeToCoredata() {
        self.moc.performBlockAndWait() {
            
        }
        super.writeToCoredata()
    }
}

//////////////////////////////////////////////////////
// MARK:- ServiceImporter (RobustImporter sublcass) -
class ServiceImporter : RobustImporter {
    
    required init(key:String, moc: NSManagedObjectContext,
                  cloudDatabase: CKDatabase,
                  recordID: CKRecordID,
                  delegate: RobustImporterDelegate) {
        
        let recordType = ICloudRecordType.Service
        super.init(key:key, moc:moc, cloudDatabase:cloudDatabase, recordType:recordType, recordID:recordID, delegate:delegate)
    }
    
    override func writeToCoredata() {
        self.moc.performBlockAndWait() {
            
        }
        super.writeToCoredata()
    }
}

//////////////////////////////////////////////////////
// MARK:- EmployeeImporter (RobustImporter sublcass) -
class EmployeeImporter : RobustImporter {
    
    required init(key:String, moc: NSManagedObjectContext,
                  cloudDatabase: CKDatabase,
                  recordID: CKRecordID,
                  delegate: RobustImporterDelegate) {
        
        let recordType = ICloudRecordType.Employee
        super.init(key:key, moc:moc, cloudDatabase:cloudDatabase, recordType:recordType, recordID:recordID, delegate:delegate)
    }
    
    override func writeToCoredata() {
        self.moc.performBlockAndWait() {
            
        }
        super.writeToCoredata()
    }
}


