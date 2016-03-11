//
//  ImportInfoCell.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 11/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class ImportInfoCell : UITableViewCell {
    
    weak var error:NSError? {
        didSet {
            if error == nil {
                self.showErrorButton.hidden = true
            } else {
                self.showErrorButton.hidden = false                
            }
        }
    }
    
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    @IBOutlet weak var recordTypeLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var showErrorButton: UIButton!
    @IBAction func showError(sender:AnyObject) {
        print("\(error)")
    }
}
