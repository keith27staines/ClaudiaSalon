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
    func incrementIfZero() -> Bool {
        var didIncrement = false
        dispatch_sync(synchronisationQueue) {
            if self.count > 0 {
                self.count++
                didIncrement = true
            }
        }
        return didIncrement
    }
    func increment() {
        dispatch_sync(synchronisationQueue) {self.count++}
    }
    func decrement() {
        dispatch_sync(synchronisationQueue) {
            precondition(self.count > 0, "Counter is being illegally decremented")
            self.count--
        }
    }
    func zero() {
        dispatch_sync(synchronisationQueue) {self.count == 0 }
    }
}