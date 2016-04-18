//
//  SalonTableViewCell.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 17/04/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit
import CloudKit

class SalonTableViewCell : UITableViewCell {
    
    private let UnknownName = "Downloading name..."
    private let UnknownAddress = "Downloading address..."
    
    @IBOutlet weak var salonRecordName: UILabel!
    
    @IBOutlet weak var salonName: UILabel!
    
    @IBOutlet weak var salonAddress: UILabel!
    
    func configureWithRecordName(recordName:String) {
        self.salonRecordName.text = "Cloud ID: \(recordName)"
        self.salonName.text = UnknownName
        self.salonAddress.text = UnknownAddress
    }
    
    func configureWithRecord(record:CKRecord) {
        self.salonRecordName.text = record.recordID.recordName
        self.salonName.text = record["name"] as? String ?? ""
        var address = ""
        if let addressLine1 = record["addressLine1"] as? String {
            address += addressLine1
        }
        if let addressLine2 = record["addressLine2"] as? String {
            address += ", " + addressLine2
        }
        if let postcode = record["postcode"] as? String {
            address += ", " + postcode
        }
        if address.characters.count == 0 {
            self.salonAddress.text = UnknownAddress
        } else {
            self.salonAddress.text = address
        }
    }
}
