//
//  SaleDetailCellTableViewCell.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 02/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class SaleDetailCellTableViewCell: UITableViewCell {

    @IBOutlet weak var actualPrice: UILabel!
    private var saleItem:SaleItem?
    
    func updatedWithSaleItem(saleItem:SaleItem) {
        var actualPrice:NSNumber?
        self.saleItem = saleItem
        self.saleItem?.managedObjectContext?.performBlockAndWait() {
            actualPrice = self.saleItem?.actualCharge
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                self.actualPrice.text = "Price " + (self.stringForCurrencyAmount(actualPrice) ?? "")
            }
        }
    }
    private func stringForCurrencyAmount(amount:NSNumber?) -> String? {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = .CurrencyStyle
        formatter.locale = NSLocale.currentLocale()
        guard let amount = amount else {
            return nil
        }
        return formatter.stringFromNumber(amount)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
