//
//  ImportData.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 18/05/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit
import CoreData

// MARK: - ImportData Struct
struct ImportData {
    private (set) var recordType: ICloudRecordType?
    var recordID: CKRecordID?
    var coredataID: String?
    var cloudRecord: CKRecord?
    var coredataRecord: NSManagedObject?
    var error: NSError?
    var state: ImportState
    
    init(recordType:ICloudRecordType) {
        self.recordType = recordType
        self.state = .InPreparation
    }
}

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
    case DownloadedRecord
    case FailedToDownloadRecord(NSError?)
    case AddingChildImporters
    case AddedChildImporters
    case FailedToAddChildImporters(NSError?)
    case DownloadingChildRecords
    case AllRequiredDataDownloaded
    case FailedToDownloadRequiredChild(NSError?)
    case WritingToCoredata
    case FailedToWriteToCoredata(NSError?)
    case Complete
    case InvalidState
    
    func isInPreparationState() -> Bool {
        return self == ImportState.InPreparation
    }
    func isComplete() -> Bool {
        return self == ImportState.Complete
    }
    
    func isWorkingState() -> Bool {
        switch self {
        case .DownloadingRecord,
             .DownloadedRecord,
             .AddingChildImporters,
             .AddedChildImporters,
             .DownloadingChildRecords,
             .AllRequiredDataDownloaded,
             .WritingToCoredata:
            return true
            
        case .InPreparation,
             .FailedToDownloadRecord,
             .FailedToAddChildImporters,
             .FailedToDownloadRequiredChild,
             .FailedToWriteToCoredata,
             .InvalidState,
             .Complete:
            return false
        }
    }
    func isErrorState() -> Bool {
        switch self {
        case .InvalidState,
             .FailedToDownloadRecord,
             .FailedToAddChildImporters,
             .FailedToDownloadRequiredChild,
             .FailedToWriteToCoredata:
            return true
        case .InPreparation,
             .DownloadingRecord,
             .DownloadedRecord,
             .AddingChildImporters,
             .AddedChildImporters,
             .DownloadingChildRecords,
             .AllRequiredDataDownloaded,
             .WritingToCoredata,
             .Complete:
            return false
        }
    }
    func isFinalState() -> Bool {
        switch self {
        case .Complete,
             .InvalidState,
             .FailedToDownloadRecord,
             .FailedToAddChildImporters,
             .FailedToDownloadRequiredChild,
             .FailedToWriteToCoredata:
            return true
        default:
            return false
        }
    }
}


extension ImportState: Equatable {
}

func ==(lhs: ImportState, rhs: ImportState) -> Bool {
    switch lhs {
        
    case .InPreparation: switch rhs { case .InPreparation: return true; default: return false }
        
    case .DownloadingRecord: switch rhs { case .DownloadingRecord: return true; default: return false }
        
    case .FailedToDownloadRecord: switch rhs { case .FailedToDownloadRecord: return true; default: return false }
        
    case .DownloadedRecord: switch rhs { case .DownloadedRecord: return true; default: return false }
        
    case .AddingChildImporters: switch rhs { case .AddingChildImporters: return true; default: return false }
        
    case .FailedToAddChildImporters: switch rhs { case .FailedToAddChildImporters: return true; default: return false }
        
    case .AddedChildImporters: switch rhs { case .AddedChildImporters: return true; default: return false }
        
    case .DownloadingChildRecords: switch rhs { case .DownloadingChildRecords: return true; default: return false }
        
    case .FailedToDownloadRequiredChild: switch rhs { case .FailedToDownloadRequiredChild: return true; default: return false }
        
    case .AllRequiredDataDownloaded: switch rhs { case .AllRequiredDataDownloaded: return true; default: return false }
        
    case .WritingToCoredata: switch rhs { case .WritingToCoredata: return true; default: return false }
        
    case .FailedToWriteToCoredata: switch rhs { case .FailedToWriteToCoredata: return true; default: return false }
        
    case .Complete: switch rhs { case .Complete: return true; default: return false }
        
    case .InvalidState: switch rhs { case .InvalidState: return true; default: return false }
    }
}

