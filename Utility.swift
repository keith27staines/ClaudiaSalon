//
//  Utility.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 14/05/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation

enum Result {
    case success
    case failure(NSError)
}

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
