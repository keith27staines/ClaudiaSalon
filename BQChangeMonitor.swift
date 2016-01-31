
//
//  BQChangeMonitor.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

class BQChangeMonitor {
    let queue = NSOperationQueue()
    init() {
        NSNotificationCenter.defaultCenter().addObserverForName(NSManagedObjectContextObjectsDidChangeNotification, object: nil, queue: queue) { notification in
            if let updated = notification.userInfo?[NSUpdatedObjectsKey] where updated.count > 0 {
                print("updated: \(updated)")
            }
            
            if let deleted = notification.userInfo?[NSDeletedObjectsKey] where deleted.count > 0 {
                print("deleted: \(deleted)")
            }
            
            if let inserted = notification.userInfo?[NSInsertedObjectsKey] where inserted.count > 0 {
                print("inserted: \(inserted)")
            }
            self.queue.addOperationWithBlock({ () -> Void in
                
            })
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}