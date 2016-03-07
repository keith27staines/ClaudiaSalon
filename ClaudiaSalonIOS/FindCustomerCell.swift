//
//  FindCustomerCell.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 07/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class FindCustomerCell: UITableViewCell {
    var customer:Customer? {
        didSet {
            guard let customer = customer else {
                self.textLabel?.text = ""
                self.detailTextLabel?.text = ""
                return
            }
            self.textLabel!.text = customer.fullName!
            self.detailTextLabel!.text = customer.phone
        }
    }
}
