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

    // MARK - Subclasses should override this method
    class func getRecordType() -> ICloudRecordType {
        fatalError("Subclasses must override this property")
    }
    
    // MARK: - API properties
    private (set) var key: String
    private (set) var recordID: CKRecordID
    private (set) var importData:ImportData
    private (set) var childImporters = [String:RobustImporter]()
    private (set) var successRequired = false
    private var recordType: ICloudRecordType {
        return self.dynamicType.getRecordType()
    }

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
    
    
    // MARK: - Private initializer
    
    /// Designated initializer
    init(key:String,
         moc:NSManagedObjectContext,
         cloudDatabase:CKDatabase,
         recordID:CKRecordID,
         record:CKRecord?,
         successRequired:Bool,
         delegate:RobustImporterDelegate) {
        
        let myRecordType = self.dynamicType.getRecordType()
        if let record = record {
            if record.recordType != myRecordType.rawValue {
                fatalError("The record is of type \(record.recordType) and cannot be used to initialize an importer of type \(myRecordType.rawValue)")
            }
        }

        self.key = key
        self.moc = moc
        self.cloudDatabase = cloudDatabase
        self.recordID = recordID
        self.successRequired = successRequired
        self.delegate = delegate
        self.importData = ImportData(recordType:myRecordType)
        self.importData.recordID = recordID
        self.importData.cloudRecord = record
        self.childImporters = [String:RobustImporter]()
    }

    // MARK:- API methods
        
    /// Start import. The receiver will automatically determine the appropriate start point
    func startImport() {
        if let record = self.importData.cloudRecord {
            self.handleFetchedPrimaryRecord(record, error: nil)
        } else {
            self.changeState(.DownloadingRecord)
        }
    }
    
    // Override this method if necessary, but call super to automatically take care of state changes and notifications.
    // Note that the implementation of this function is martialled onto the synchronization queue
    private func handleFetchedPrimaryRecord(record:CKRecord?, error:NSError?) {
        self.synchQueue.addOperationWithBlock() {
            if let error = error {
                self.changeState(ImportState.FailedToDownloadRecord(error))
                return
            }
            if let record = record {
                self.importData.cloudRecord = record
                self.changeState(.AddingChildImporters)
            }
        }
    }
    
    // Mark: Add child importers and handle completion
    
    /// Initiate the creation of child importers
    private func startAddingChildImporters() {}
    
    /// Check that all child record importers have at least been constructed and added
    private func verifyRequiredChildImportersWereAdded() -> Result {
        fatalError("Subclasses must override this and provide their own logic")
    }
    
    /// Handle the completion of adding child importers. 
    ///
    /// Parameter 'result' just indicates the success or failure of the operation, but this method performs its own check to determine if all required child importers were added
    private final func handleAddingChildImportersCompleted(result:Result) {
        switch result {
        case Result.success:
            let verifyResult = self.verifyRequiredChildImportersWereAdded()
            switch verifyResult {
            case Result.success:
                self.changeState(.DownloadingChildRecords)
            case Result.failure(let veryifyError):
                self.changeState(ImportState.FailedToDownloadRequiredChild(veryifyError))
            }
        case Result.failure(let error):
            self.changeState(ImportState.FailedToAddChildImporters(error))
        }
    }

    // Start downloading child records and handle completion
    private final func startChildRecordImporters() {
        self.changeState(.DownloadingChildRecords)
        if self.childImporters.count == 0 {
            self.changeState(ImportState.AllRequiredDataDownloaded)
            return
        }
        for (_,importer) in self.childImporters {
            importer.startImport()
        }
    }
    
    // Return state information
    func state() -> ImportState {
        return self.importData.state
    }
    
    // MARK:- RobustImporterDelegate
    func importDidFail(importer: RobustImporter) {
        switch importer.state() {
        case .InvalidState:
            self.changeState(ImportState.FailedToDownloadRequiredChild(nil))
        case ImportState.FailedToDownloadRecord(let error):
            self.changeState(ImportState.FailedToDownloadRequiredChild(error))
        case ImportState.FailedToAddChildImporters(let error):
            self.changeState(ImportState.FailedToAddChildImporters(error))
        case ImportState.FailedToDownloadRequiredChild(let error):
            self.changeState(ImportState.FailedToDownloadRequiredChild(error))
        case ImportState.FailedToWriteToCoredata(let error):
            self.changeState(ImportState.FailedToWriteToCoredata(error))
            
        // Cases where the importer is not in an error state should never be met
        case ImportState.InPreparation,
             ImportState.DownloadingRecord,
             ImportState.AddingChildImporters,
             ImportState.DownloadingChildRecords,
             ImportState.AllRequiredDataDownloaded,
             ImportState.WritingToCoredata,
             ImportState.Complete:
            fatalError("The importer is not in a failed state but is reporting failure")
        }
    }
    
    func importDidProgressState(importer: RobustImporter) {
        // If our child imports are all downloaded, then we are downloaded. If any one of them hasn't downloaded, then neither are we
        if  self.importData.state == ImportState.DownloadingChildRecords && self.isAllChildDataDownloaded() {
            self.changeState(.AllRequiredDataDownloaded)
            return
        }
        
        // If our child imports are all downloaded, then we are downloaded. If any one of them hasn't downloaded, then neither are we
        if self.importData.state == ImportState.WritingToCoredata && self.isAllChildDataComplete() {
            self.changeState(.Complete)
            return
        }
    }

    // MARK: - Implementation
    
    /// Permorms a shallow updates the coredata record corresponding to the icloud record. Shallow means that only the ids of directly referenced objects withing the record are updated, but the referenced objects themselves are left alone. 
    ///
    /// If no coredata object currently exists for the cloud id, then one is created
    func createOrUpdatePrimaryCoredataRecord() -> BQExportable {
        var bqExportable:BQExportable!
        self.moc.performBlockAndWait() {
            let recordName = self.importData.cloudRecord!.recordID.recordName
            let BQType = classTypeForRecordType(self.recordType)
            bqExportable = BQType.fetchBQExportable(recordName, moc: self.moc)
            if bqExportable == nil {
                bqExportable = BQType.newExportableWithMoc(self.moc)
            }
            bqExportable.updateFromCloudRecord(self.importData.cloudRecord!)
            self.importData.coredataRecord = (bqExportable as! NSManagedObject)
        }
        return bqExportable
    }
    
    /// This base class implementation simply writes the primary record to the coredata context and saves the context. 
    ///
    /// Subclasses that have child records should perform a similar function but additionally they should set the child references and ensure they call saveCoredataContext
    func writeToCoredata() {
        let _ = self.createOrUpdatePrimaryCoredataRecord()
        self.saveCoredataContext()
    }
    
    func saveCoredataContext() {
        self.moc.performBlockAndWait() {
            guard self.moc.hasChanges else {
                return
            }
            do {
                try self.moc.save()
                self.changeState(ImportState.Complete)
            } catch let error as NSError {
                self.changeState(ImportState.FailedToWriteToCoredata(error))
            }
        }
    }
    
    private func isAllChildDataDownloaded() -> Bool {
        for (_,importer) in self.childImporters {
            let state = importer.importData.state
            if importer.successRequired {
                if state != ImportState.AllRequiredDataDownloaded { return false }
            } else {
                // As not required, error states count as downloaded
                if !importer.state().isErrorState() {
                    // But if not in error state, then it must be in the fully downloaded state
                    if importer.importData.state != ImportState.AllRequiredDataDownloaded { return false }
                }
            }
        }
        return true
    }
    private func isAllChildDataComplete() -> Bool {
        for (_,importer) in self.childImporters {
            let state = importer.importData.state
            if importer.successRequired {
                if state != ImportState.Complete { return false }
            } else {
                // As not required, error states count as complete
                if !importer.state().isErrorState() {
                    // But if not in error state, then it must be complete
                    if importer.importData.state != ImportState.Complete { return false }
                }
            }
        }
        return true
    }
}

// MARK:- State machine
extension RobustImporter {
    private func changeState(nextState:ImportState) {
        self.synchQueue.addOperationWithBlock() {

            let currentState = self.importData.state
            self.ensureStateTransitionIsValid(currentState, nextState: nextState)
            self.importData.state = nextState
            self.delegate?.importDidProgressState(self)
            
            switch nextState {
            case .InPreparation: break
            case .DownloadingRecord:
                self.cloudDatabase.fetchRecordWithID(self.recordID, completionHandler: self.handleFetchedPrimaryRecord)
            case .AddingChildImporters:
                self.startAddingChildImporters()
                break
            case .DownloadingChildRecords:
                self.startChildRecordImporters()
            case .AllRequiredDataDownloaded:
                self.changeState(ImportState.WritingToCoredata)
                break
            case .WritingToCoredata:
                self.writeToCoredata()
            case .Complete:
                break
            case ImportState.FailedToDownloadRecord(let error):
                self.importData.error = error
                self.delegate.importDidFail(self)
            case ImportState.FailedToAddChildImporters(let error):
                self.importData.error = error
                self.delegate.importDidFail(self)
            case ImportState.FailedToDownloadRequiredChild(let error):
                self.importData.error = error
                self.delegate.importDidFail(self)
            case ImportState.FailedToWriteToCoredata(let error):
                self.importData.error = error
                self.delegate.importDidFail(self)
            case ImportState.InvalidState: break
                self.delegate.importDidFail(self)
            }
        }
    }
    
    private func ensureStateTransitionIsValid(currentState:ImportState, nextState:ImportState) {
        let allowedNextStates = self.allowedNextStates(currentState)
        for allowedState in  allowedNextStates {
            if allowedState == nextState {
                return
            }
        }
        fatalError("There is no legal transition from \(currentState) to \(nextState)")
    }
    
    func allowedNextStates(currentState:ImportState) -> [ImportState] {
        var allowedStates = [ImportState]()
        switch currentState {
        case .InPreparation:
            allowedStates.append(ImportState.DownloadingRecord)
            
        case .DownloadingRecord:
            allowedStates.append(ImportState.FailedToDownloadRecord(nil))
            allowedStates.append(ImportState.AddingChildImporters)
            
        case .AddingChildImporters:
            allowedStates.append(ImportState.DownloadingChildRecords)
            allowedStates.append(ImportState.FailedToDownloadRecord(nil))
        case .DownloadingChildRecords:
            allowedStates.append(ImportState.AllRequiredDataDownloaded)
            allowedStates.append(ImportState.FailedToDownloadRequiredChild(nil))
        case .AllRequiredDataDownloaded:
            allowedStates.append(ImportState.WritingToCoredata)
        case .WritingToCoredata:
            allowedStates.append(ImportState.Complete)
            allowedStates.append(ImportState.FailedToWriteToCoredata(nil))
        
        // End states cannot be transitioned to anything else
        case .FailedToDownloadRecord,
             .FailedToAddChildImporters,
             .FailedToDownloadRequiredChild,
             .FailedToWriteToCoredata,
             .InvalidState,
             .Complete:
            break
        }
        return allowedStates
    }
}

// MARK: - Convenience methods

extension RobustImporter {
    
    func addChildImporter(baseKey:String,importer:RobustImporter) {
        self.synchQueue.addOperationWithBlock {
            let key = self.constructKeyFromBase(baseKey)
            importer.key = key
            self.childImporters[key] = importer
        }
    }
    func constructKeyFromBase(baseKey:String) -> String {
        var key = baseKey
        var i = 0
        while let _ = self.childImporters[key] {
            key = baseKey + String(i)
            i += 1
        }
        return key
    }
}

/////////////////////////////////
// MARK: - Fetching child records
extension RobustImporter {
    private var referenceFieldNameForChildren:String {
        let recordType = self.recordType
        let cloudRecordType = CloudRecordType(rawValue: recordType.rawValue)
        let entityName = CloudRecordType.coredataEntityNameForType(cloudRecordType!)
        let fieldname = "parent" + entityName + "Reference"
        return fieldname
    }
    private func makeFetchChildRecordsOperation(childRecordType:ICloudRecordType) -> CKQueryOperation {
        let predicate = NSPredicate(format: "\(self.referenceFieldNameForChildren) = %@", self.selfReference!)
        let query = CKQuery(recordType: childRecordType.rawValue, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        self.addCompletionBlockToChildFetchOperation(queryOperation)
        return queryOperation
    }
    private func makeFetchChildRecordOperation(parentOperation:CKQueryOperation,cursor:CKQueryCursor) -> CKQueryOperation {
        let queryOperation = CKQueryOperation(cursor: cursor)
        queryOperation.recordFetchedBlock = parentOperation.recordFetchedBlock
        self.addCompletionBlockToChildFetchOperation(queryOperation)
        return queryOperation
    }
    
    /// Equip the child record fetch operation with a query completion block
    private func addCompletionBlockToChildFetchOperation(queryOperation:CKQueryOperation) {
        queryOperation.name = "fetchChildOperation"
        queryOperation.queryCompletionBlock = { cursor, error in

            if let error = error {
                self.changeState(ImportState.FailedToDownloadRequiredChild(error))
                self.handleAddingChildImportersCompleted(Result.failure(error))
                return
            }
            if let cursor = cursor {
                self.cloudDatabase.addOperation(self.makeFetchChildRecordOperation(queryOperation,cursor:cursor))
                return
            }
            self.handleAddingChildImportersCompleted(Result.success)
        }
    }
}

////////////////////////////////////////////////
// MARK:- ChildlessRobustImporter (RobustImporter abstract sublcass) -
class ChildlessRobustImporter : RobustImporter {
    
    final override func startAddingChildImporters() {
        super.startAddingChildImporters()
        // We have no children, therefore just register success
        self.handleAddingChildImportersCompleted(Result.success)
    }
    
    /// Check that all child record importers have at least been constructed and added
    override private func verifyRequiredChildImportersWereAdded() -> Result {
        return Result.success
    }
}

////////////////////////////////////////////////
// MARK:- AppointmentImporter (RobustImporter sublcass) -
class AppointmentImporter : RobustImporter {
    
    // Importers for directly referenced child objects (ids are known)
    private let customerKey = "parentCustomerReference"
    private var customerRecordID:CKRecordID!
    private var customerImporter: CustomerImporter?
    
    // Importers for indirectly referenced objects (no id is known)
    private var saleFetcher: CKQueryOperation!
    private let saleKey = "sale"
    private var saleRecordID:CKRecordID!
    private var saleImporter: SaleImporter?
    
    override var recordType:ICloudRecordType { return ICloudRecordType.Appointment }
    
    private override func handleFetchedPrimaryRecord(record: CKRecord?, error: NSError?) {
        if let record = record {
            let customerReference = record[customerKey] as! CKReference
            self.customerRecordID = customerReference.recordID
        }
        super.handleFetchedPrimaryRecord(record, error: error)
    }
    
    override func startAddingChildImporters() {
        // Add customer importer - we already have the customer id
        self.customerImporter = CustomerImporter(key: self.customerKey, moc: self.moc, cloudDatabase: self.cloudDatabase, recordID: self.customerRecordID , record: nil, successRequired:true, delegate: self)
        self.addChildImporter(self.customerKey,importer: self.customerImporter!)
        
        // Add importers for child records for which we don't yet have recordIDs
        saleFetcher = self.makeFetchChildRecordsOperation(ICloudRecordType.Sale)
        saleFetcher.recordFetchedBlock = { [weak self] record in
            let recordID = record.recordID
            guard let weakSelf = self else {
                return
            }
            let importer = SaleImporter(key: weakSelf.saleKey, moc: weakSelf.moc, cloudDatabase: weakSelf.cloudDatabase, recordID: recordID, record: record, successRequired: true, delegate: weakSelf)
            weakSelf.addChildImporter(weakSelf.saleKey,importer: importer)
            weakSelf.saleImporter = importer
        }
        self.cloudDatabase.addOperation(saleFetcher)
    }
    
    /// Check that all child record importers have at least been constructed and added
    override private func verifyRequiredChildImportersWereAdded() -> Result {
        if self.saleImporter == nil {
            let userInfo = [NSLocalizedDescriptionKey: "Missing importer",
                            NSLocalizedFailureReasonErrorKey: "No Sale was found for this appointment"]
            let error = NSError(domain: "uk.co.ClaudiaSalon", code: 1, userInfo: userInfo)
            return Result.failure(error)
        }
        return Result.success
    }
    
    override func writeToCoredata() {
        let appointment = super.createOrUpdatePrimaryCoredataRecord() as! Appointment
        self.moc.performBlockAndWait() {
            appointment.customer = (self.customerImporter!.importData.coredataRecord as! Customer)
            appointment.sale = (self.saleImporter!.importData.coredataRecord as! Sale)
        }
        self.saveCoredataContext()
    }
}

//////////////////////////////////////////////////////
// MARK:- SaleImporter (RobustImporter sublcass) -
class SaleImporter : RobustImporter {
    
    // Importers for directly referenced child objects (ids are known)
    private let customerKey = "customer"
    private var customerRecordID:CKRecordID!
    private var customerImporter: CustomerImporter?
    
    // Importers for indirectly referenced objects (no id is known)
    private var childRecordFetcher: CKQueryOperation!
    private let saleItemKey = "saleItem"
    private var saleItemImporters = [SaleItemImporter]()
    
    override var recordType: ICloudRecordType { return ICloudRecordType.Sale }
    
    private override func handleFetchedPrimaryRecord(record: CKRecord?, error: NSError?) {
        if let record = record {
            let customerReference = record[customerKey] as! CKReference
            self.customerRecordID = customerReference.recordID
        }
        super.handleFetchedPrimaryRecord(record, error: error)
    }
    
    override func startAddingChildImporters() {
        // Add customer importer - we already have the customer id
        self.customerImporter = CustomerImporter(key: self.customerKey, moc: self.moc, cloudDatabase: self.cloudDatabase, recordID: self.customerRecordID , record: nil, successRequired:true, delegate: self)
        self.addChildImporter(self.customerKey,importer: self.customerImporter!)
        
        // Add importers for child records for which we don't yet have recordIDs
        childRecordFetcher = self.makeFetchChildRecordsOperation(ICloudRecordType.SaleItem)
        childRecordFetcher.recordFetchedBlock = { [weak self] record in
            let recordID = record.recordID
            guard let weakSelf = self else {
                return
            }
            let importer = SaleItemImporter(key: weakSelf.saleItemKey, moc: weakSelf.moc, cloudDatabase: weakSelf.cloudDatabase, recordID: recordID, record: record, successRequired: true, delegate: weakSelf)
            weakSelf.addChildImporter(weakSelf.saleItemKey,importer: importer)
        }
        self.cloudDatabase.addOperation(childRecordFetcher)
    }
    
    /// Check that all child record importers have at least been constructed and added
    override private func verifyRequiredChildImportersWereAdded() -> Result {
        return Result.success
    }
    
    override func writeToCoredata() {
        let sale = super.createOrUpdatePrimaryCoredataRecord() as! Sale
        self.moc.performBlockAndWait() {
            sale.customer = (self.customerImporter!.importData.coredataRecord as! Customer)
            for importer in self.saleItemImporters {
                let saleItem = importer.importData.coredataRecord as! SaleItem
                sale.addSaleItemObject(saleItem)
            }
        }
        self.saveCoredataContext()
    }
}


//////////////////////////////////////////////////////
// MARK:- CustomerImporter (ChildlessRobustImporter sublcass) -
class CustomerImporter : ChildlessRobustImporter {
    
    override var recordType: ICloudRecordType { return ICloudRecordType.Customer }

}

//////////////////////////////////////////////////////
// MARK:- SaleItemImporter (RobustImporter sublcass) -
class SaleItemImporter : RobustImporter {
    
    // Importers for directly referenced child objects (ids are known)
    private let serviceKey = "serviceReference"
    private var serviceRecordID:CKRecordID!
    private var serviceImporter: ServiceImporter?
    
    private let employeeKey = "employeeReference"
    private var employeeRecordID: CKRecordID!
    private var employeeImporter: EmployeeImporter?
    
    override var recordType: ICloudRecordType { return ICloudRecordType.SaleItem }
    
    private override func handleFetchedPrimaryRecord(record: CKRecord?, error: NSError?) {
        if let record = record {
            let customerReference = record[serviceKey] as! CKReference
            self.serviceRecordID = customerReference.recordID
            let employeeReference = record[employeeKey] as! CKReference
            self.employeeRecordID = employeeReference.recordID
        }
        super.handleFetchedPrimaryRecord(record, error: error)
    }
    
    private override func startAddingChildImporters() {
        self.serviceImporter = ServiceImporter(key: serviceKey, moc: moc, cloudDatabase: cloudDatabase, recordID: serviceRecordID, record: nil, successRequired: true, delegate: self)
        self.employeeImporter = EmployeeImporter(key: employeeKey, moc: moc, cloudDatabase: cloudDatabase, recordID: employeeRecordID, record: nil, successRequired: false, delegate: self)
        self.addChildImporter(serviceKey, importer: serviceImporter!)
        self.addChildImporter(employeeKey, importer: employeeImporter!)
        self.handleAddingChildImportersCompleted(Result.success)
    }
    
    private override func verifyRequiredChildImportersWereAdded() -> Result {
        return Result.success
    }
    
    override func writeToCoredata() {
        let saleItem = self.createOrUpdatePrimaryCoredataRecord() as! SaleItem
        self.moc.performBlockAndWait() {
            saleItem.service = (self.serviceImporter!.importData.coredataRecord as! Service)
            saleItem.performedBy = (self.employeeImporter!.importData.coredataRecord as! Employee)
        }
        self.saveCoredataContext()
    }
}

//////////////////////////////////////////////////////
// MARK:- ServiceImporter (ChildlessRobustImporter sublcass) -
class ServiceImporter : ChildlessRobustImporter {
    
    override var recordType: ICloudRecordType { return ICloudRecordType.Service }

}

//////////////////////////////////////////////////////
// MARK:- EmployeeImporter (ChildlessRobustImporter sublcass) -
class EmployeeImporter : ChildlessRobustImporter {

    override var recordType: ICloudRecordType { return ICloudRecordType.Employee }

}

//////////////////////////////////////////////////////
// MARK:- SalonImporter (ChildlessRobustImporter sublcass) -
class SalonImporter : ChildlessRobustImporter {

    override var recordType: ICloudRecordType { return ICloudRecordType.Salon }

}

//////////////////////////////////////////////////////
// MARK:- ServiceCategoryImporter (ChildlessRobustImporter sublcass) -
class ServiceCategoryImporter : ChildlessRobustImporter {

    override var recordType: ICloudRecordType { return ICloudRecordType.ServiceCategory }

}


