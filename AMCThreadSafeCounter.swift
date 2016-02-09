//
//  AMCThreadSafeCounter.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 07/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation


class AMCThreadSafeCounter {
    private (set) var count = 0
    private let synchronisationQueue = dispatch_queue_create("com.AMCAldebaron.AMCThreadSafeCounter", DISPATCH_QUEUE_SERIAL)

    init(initialValue:Int) {
        count = initialValue
    }
    func increment() {
        dispatch_sync(synchronisationQueue) {self.count++}
    }
    func decrement() {
        dispatch_sync(synchronisationQueue) {self.count--}
    }
    func zero() {
        dispatch_sync(synchronisationQueue) {self.count == 0 }
    }
}