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
    case FailedToDownloadRecord(NSError?)
    case AddingChildImporters
    case FailedToAddChildImporters(NSError?)
    case DownloadingChildRecords
    case FailedToDownloadRequiredChild(NSError?)
    case AllRequiredDataDownloaded
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
        case .DownloadingRecord, .AddingChildImporters, .DownloadingChildRecords,.AllRequiredDataDownloaded:
            return true
        default:
            return false
        }
    }
    func isErrorState() -> Bool {
        switch self {
        case .FailedToDownloadRecord,
             .FailedToAddChildImporters,
             .FailedToDownloadRequiredChild,
             .FailedToWriteToCoredata:
            return true
        default:
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
    switch (lhs, rhs) {
    case (.InPreparation,.InPreparation): return true
    case (.DownloadingRecord,.DownloadingRecord): return true
    case (.FailedToDownloadRecord,.FailedToDownloadRecord): return true
    case (.AddingChildImporters,.AddingChildImporters): return true
    case (.FailedToAddChildImporters,.FailedToAddChildImporters): return true
    case (.DownloadingChildRecords,.DownloadingChildRecords): return true
    case (.FailedToDownloadRequiredChild,.FailedToDownloadRequiredChild): return true
    case (.AllRequiredDataDownloaded,.AllRequiredDataDownloaded): return true
    case (.WritingToCoredata,.WritingToCoredata): return true
    case (.FailedToWriteToCoredata,.FailedToWriteToCoredata): return true
    case (.Complete,.Complete): return true
    case (.InvalidState,.InvalidState): return true
    default: return false
    }
}

