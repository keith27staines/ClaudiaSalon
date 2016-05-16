//
//  Utility.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 14/05/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation

// MARK:- Return result enumeration
enum Result {
    case success
    case failure(NSError)
}

// MARK:- Array extension
extension Array {
    func subdivideAtIndex(index:Int)->(left: [Element], right: [Element]) {
        guard index >= 0 && index < self.count else {
            fatalError("Tried to divide array containing \(self.count) items at index \(index)")
        }
        let leftSplit = self[0 ..< index]
        let rightSplit = self[index ..< self.count]
        return (left: Array(leftSplit), right: Array(rightSplit))
    }
}

//MARK:- Dispatch after helpers
func waitAndDispatchOnQueue(waitSeconds:Double,queue:dispatch_queue_t, performBlock:()->Void) {
    let waitIntervalNanoseconds = Int64(waitSeconds * Double(NSEC_PER_SEC))
    let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, waitIntervalNanoseconds)
    dispatch_after(dispatchTime, dispatch_get_main_queue()) { performBlock() }
}

func waitAndDispatchOnMainQueue(waitSeconds:Double, performBlock:()->Void) {
    let mainQueue = dispatch_get_main_queue()
    waitAndDispatchOnQueue(waitSeconds, queue: mainQueue) { performBlock() }
}

//MARK:-