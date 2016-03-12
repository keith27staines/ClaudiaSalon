//
//  DownloadInfo.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 12/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation

struct DownloadInfo {
    var recordType: CloudRecordType
    var activeOperations = 0
    var recordsDownloaded = 0
    var error:NSError?
    var downloadStatus: String {
        if self.waiting {
            if activeOperations == 0 {
                return ""
            } else {
                return "Waiting for server"
            }
        }
        if self.executing { return "\(recordsDownloaded) downloaded" }
        if self.finished {
            if error != nil {
                return "Encountered error after \(recordsDownloaded) records"
            } else {
                return "Finished downloading \(recordsDownloaded) record(s)"
            }
        }
        assertionFailure("Invalid state")
        return "Invalid state"
    }
    var executing = false
    var finished = false
    var waiting = true
    init(recordType:CloudRecordType) {
        self.recordType = recordType
    }
}
