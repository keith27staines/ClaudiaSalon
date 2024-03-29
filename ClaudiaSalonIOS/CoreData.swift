
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
    private static var instances = [String:Coredata]()
    private (set) static var sharedInstance:Coredata!
    static let cloudContainerID = "iCloud.uk.co.ClaudiasSalon.ClaudiaSalon"
    
    class func coredataForKey(recordName:String) -> Coredata {
        var instance = self.instances[recordName]
        if instance == nil {
            instance = Coredata(cloudContainerIdentifier:self.cloudContainerID , cloudSalonRecordName: recordName)
            self.instances[recordName] = instance
        }
        return instance!
    }
    
    class func setSharedInstance(cloudSalonRecordName:String) {
        let coredata = self.coredataForKey(cloudSalonRecordName)
        self.sharedInstance = coredata
    }
    
    class func forgetSalon(recordName:String,completion:(success:Bool)->Void) {
        let coredata = self.coredataForKey(recordName)
        if coredata === self.sharedInstance {
            self.sharedInstance = nil
        }
        Coredata.instances[recordName] = nil
        coredata.exportController.suspendExportIterations()
        coredata.importController.suspendCloudNotificationProcessing()
        coredata.importController.forgetSalon { (success) in
            if success {
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(coredata.fileURL)
                } catch {
                    assertionFailure("Failed to delete datastore for \(recordName) with error \(error)")
                }
            }
            completion(success: success)
        }
    }
    
    deinit {
        self.save(true)
    }
    
    private init(cloudContainerIdentifier:String, cloudSalonRecordName:String) {
        self.iCloudContainerIdentifier = cloudContainerIdentifier
        self.iCloudSalonRecordName = cloudSalonRecordName
    }
    
    private (set) var iCloudContainerIdentifier:String
    private (set) var iCloudSalonRecordName:String
    private var fileURL: NSURL!
    
    lazy var exportController:BQCoredataExportController = BQCoredataExportController(parentMoc: self.managedObjectContext, iCloudContainerIdentifier: self.iCloudContainerIdentifier, startProcessingImmediately: false)
    
    lazy var importController:BQCloudImporter = {
        var importer = BQCloudImporter(parentMoc:self.managedObjectContext,containerIdentifier: self.iCloudContainerIdentifier, salonCloudRecordName: self.iCloudSalonRecordName)
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
        self.fileURL = self.applicationDocumentsDirectory.URLByAppendingPathComponent(self.iCloudSalonRecordName + ".salon")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: self.fileURL, options: storeOptions)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "co.uk.ClaudiaSalonIOS", code: 9999, userInfo: dict)
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
    
    // MARK: - Core Data Saving support
    
    func save (raiseFatalErrorOnFail:Bool = true) {
        guard self.managedObjectContext.hasChanges || self.saveContext.hasChanges else {
            return
        }
        self.managedObjectContext.performBlockAndWait {
            do {
                try self.managedObjectContext.save()
            } catch {
                if raiseFatalErrorOnFail {
                    fatalError("Unresolved error while saving context \(error)")
                } else {
                    print("error while saving managed object context but fatal error has been masked")
                }
            }
        }

        self.saveContext.performBlock() {
            if self.saveContext.hasChanges {
                do {
                    try self.saveContext.save()
                } catch {
                    if raiseFatalErrorOnFail {
                        fatalError("Unresolved error while saving context \(error)")
                    } else {
                        print("error while saving managed object context but fatal error has been masked")
                    }
                }
            }
        }
    }
}