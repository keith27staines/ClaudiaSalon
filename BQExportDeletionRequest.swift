//
//  BQExportDeletionRequest.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 03/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CoreData
import CloudKit

class BQExportDeletionRequest: NSManagedObject {
    
    // Insert code here to add functionality to your managed object subclass
    
    func failedWithError(error:NSError) {
        // The cloud record wasn't deleted for some reason
        self.lastAttemptedDate = NSDate()
        self.lastErrorCode = error.code
        self.lastErrorDescription = error.description
        self.actionResult = "Retry needed"
    }
    func succeeded() {
        // Request for icloud deletion was successful so delete this deletion request as it is no longer needed
        self.managedObjectContext?.deleteObject(self)
    }
}