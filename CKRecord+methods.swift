//
//  CKRecord+methods.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 30/06/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation
import CloudKit

extension CKRecord {
    func metadataFromRecord() -> NSData {
        let data = NSMutableData()
        let coder = NSKeyedArchiver(forWritingWithMutableData: data)
        self.encodeSystemFieldsWithCoder(coder)
        coder.finishEncoding()
        return data
    }
}