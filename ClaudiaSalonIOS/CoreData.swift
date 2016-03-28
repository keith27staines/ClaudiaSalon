
//
//  CoreData.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CoreData

class Coredata {
    static let sharedInstance = Coredata()

    // Hide the default initializer because this will be a singleton
    private init() {}
    var iCloudContainerIdentifier:String?
    var iCloudSalonRecordName:String?
    
    lazy var exportController:BQCoredataExportController = BQCoredataExportController(parentMoc: self.managedObjectContext, iCloudContainerIdentifier: self.iCloudContainerIdentifier!, startImmediately: false)
    
    lazy var importController:BQCloudImporter? = {
        var importer = BQCloudImporter(parentMoc:self.managedObjectContext,containerIdentifier: self.iCloudContainerIdentifier!, salonCloudRecordName: self.iCloudSalonRecordName!)
        return importer
    }()

    
    private (set) lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.KeithStaines.ClaudiaSalonIOS" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    private lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        
        let modelURL = NSBundle.mainBundle().URLForResource("ClaudiasSalon", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let storeOptions = [NSMigratePersistentStoresAutomaticallyOption:true, NSInferMappingModelAutomaticallyOption: true]
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: storeOptions)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "com.KeithStaines.ClaudiaSalonIOS", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            fatalError("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
        }
        return coordinator
    }()
    
    private lazy var saveContext: NSManagedObjectContext = {
        let saveContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        saveContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return saveContext
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the UI
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.parentContext = self.saveContext
        return managedObjectContext
    }()
    
//    lazy var backgroundContext: NSManagedObjectContext = {
//       let backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
//        backgroundContext.parentContext = self.managedObjectContext
//        return backgroundContext
//    }()
    
    // MARK: - Core Data Saving support
    
    func save () {
        guard self.managedObjectContext.hasChanges || self.saveContext.hasChanges else {
            return
        }
        self.managedObjectContext.performBlockAndWait {
            do {
                try self.managedObjectContext.save()
            } catch {
                fatalError("Unresolved error while saving context \(error)")
            }
        }

        self.saveContext.performBlock() {
            if self.saveContext.hasChanges {
                do {
                    try self.saveContext.save()
                } catch {
                    fatalError("Unresolved error while saving context \(error)")
                }
            }
        }
    }
}