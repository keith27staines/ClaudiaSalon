//
//  BQExportDeletionRequest+CoreDataProperties.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 04/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension BQExportDeletionRequest {

    @NSManaged var actionResult: String?
    @NSManaged var bqMetadata: NSData?
    @NSManaged var cloudRecordDeletionDate: NSDate?
    @NSManaged var cloudRecordName: String?
    @NSManaged var lastAttemptedDate: NSDate?
    @NSManaged var lastErrorCode: NSNumber?
    @NSManaged var lastErrorDescription: String?
    @NSManaged var managedObjectDeletionDate: NSDate?

}
