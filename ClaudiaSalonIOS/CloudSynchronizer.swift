//
//  CloudSynchronizer.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 22/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit
import CoreData


/** The responsibility of this class is to asynchronously retrieve data from the cloud and write to local coredata store */
class CloudSynchronizer {
    static var shared = {
        return CloudSynchronizer()
    }()

    private enum Throttles:Int64 {
        case minimum = 5
        case maximum = 3600
    }
    private var delay:Int64 = Throttles.minimum.rawValue
    private let syncQueue = dispatch_queue_create("CloudSynchronizer", DISPATCH_QUEUE_SERIAL)
    
    private var running:Bool {
        return !self.suspended
    }
    private var suspended:Bool {
        return self.backgroundQueue.suspended
    }
    lazy private var coredata:Coredata = {
        let coredata = Coredata.sharedInstance
        return coredata
    }()
    
    lazy private (set) var backgroundQueue:NSOperationQueue = {
        let backgroundQueue = NSOperationQueue()
        backgroundQueue.name = "com.keithstaines.CloudSynchronizer"
        backgroundQueue.qualityOfService = .Background
        backgroundQueue.maxConcurrentOperationCount = 1
        backgroundQueue.suspended = true
        return backgroundQueue
    }()
    
    private init() {
        
    }
    
    func start() {
        dispatch_sync(self.syncQueue) {
            self.backgroundQueue.suspended = false
        }
    }

    func suspend() {
        dispatch_sync(self.syncQueue) {
            self.backgroundQueue.suspended = true
        }
    }
    
    func throttleDown() {
        dispatch_sync(self.syncQueue) {
            self.delay = Throttles.minimum.rawValue
        }
    }
    
    func throttleUp() {
        dispatch_sync(self.syncQueue) {
            self.delay = Throttles.maximum.rawValue
        }
    }
    
    private func runLoop() {
        dispatch_sync(self.syncQueue) {
            self.runBody()
            let nextTime = dispatch_time(DISPATCH_TIME_NOW, self.delay)
            dispatch_after(nextTime, self.syncQueue) {
                self.runLoop()
            }
        }
    }
    
    private func runBody() {
        
        // Get cloudkit records
        // Convert cloudkit records to managed objects
        // write managed objects to local store
    }
}
