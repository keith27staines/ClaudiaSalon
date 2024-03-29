//
//  SaleDetailCellTableViewCell.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 02/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit
protocol SaleItemUpdateReceiver: class {
    func saleItemWasUpdated(saleItem:SaleItem)
}

class SaleDetailCellTableViewCell: UITableViewCell {
    weak var delegate:SaleItemUpdateReceiver?
    private (set) var saleItem:SaleItem?
    private var discountType:NSNumber?
    private var discountValue:NSNumber?
    private var beforeDiscount:NSNumber?
    var serviceInfoBlock:((cell:SaleDetailCellTableViewCell)->Void)?
    var employeeInfoBlock:((cell:SaleDetailCellTableViewCell)->Void)?
    
    @IBOutlet weak var serviceCategoryIcon: UIImageView!
    @IBOutlet weak var employeeNameLabel: UILabel!
    @IBOutlet weak var serviceNameLabel: UILabel!
    
    @IBOutlet weak var maxLabel: UILabel!
    @IBOutlet weak var minLabel: UILabel!
    @IBOutlet weak var beforeDiscountLabel: UILabel!
    @IBOutlet weak var discountValueLabel: UILabel!
    @IBOutlet weak var afterDiscountLabel:UILabel!
    @IBOutlet weak var discountTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var discountStepper: UIStepper!
    @IBOutlet weak var amountSlider: UISlider!
    
    @IBAction func discountStepperChanged(sender: UIStepper) {
        self.discountValue = NSNumber(double: sender.value)
        self.updateSaleItem()
    }
    
    @IBAction func discountTypeChanged(sender: UISegmentedControl) {
        self.discountType = NSNumber(integer: sender.selectedSegmentIndex + 1)
        self.updateSaleItem()
    }
    
    @IBAction func amountBeforeChanged(sender: UISlider) {
        let rounded = round(sender.value)
        self.beforeDiscount = NSNumber(float: rounded)
        self.updateSaleItem()
    }
    
    @IBAction func serviceInfoTapped(sender: AnyObject) {
        if let serviceInfoBlock = serviceInfoBlock {
            serviceInfoBlock(cell: self)
        }
    }
    
    @IBAction func employeeInfoTapped(sender: AnyObject) {
        if let employeeInfoBlock = employeeInfoBlock {
            employeeInfoBlock(cell: self)
        }
    }
    
    override func didMoveToSuperview() {
        self.contentView.backgroundColor = UIColor.whiteColor()
    }
    
    func updateSaleItem() {
        let saleItem = self.saleItem!
        saleItem.nominalCharge = self.beforeDiscount
        saleItem.discountType = self.discountType
        saleItem.discountValue = self.discountValue
        saleItem.updatePrice()
        saleItem.sale!.updatePriceFromSaleItems()
        self.updateWithSaleItem(saleItem)
        self.delegate?.saleItemWasUpdated(saleItem)
    }
    
    func updateWithSaleItem(saleItem:SaleItem) {
        self.saleItem = saleItem
        self.beforeDiscount = self.saleItem?.nominalCharge
        let afterDiscount = self.saleItem?.actualCharge
        self.discountType = self.saleItem?.discountType
        self.discountValue = self.saleItem?.discountValue
        let min = self.saleItem?.minimumCharge
        let max = self.saleItem?.maximumCharge
        let employeeName = self.saleItem?.performedBy?.fullName()
        
        let hideSlider = max?.doubleValue == min?.doubleValue
        if let serviceName = self.saleItem?.service?.name {
            self.serviceNameLabel.text = serviceName
            if let category = self.saleItem?.service?.serviceCategory {
                if category.isHairCategory() {
                    self.serviceCategoryIcon.image = UIImage(named: "Scissors")
                } else if category.isBeautyCategory() {
                    self.serviceCategoryIcon.image = UIImage(named: "FacePowder")
                } else {
                    self.serviceCategoryIcon.image = UIImage(named: "Package")
                }
            }
        } else {
            self.serviceNameLabel.text = "Service must be specified!"
            self.serviceCategoryIcon.image = UIImage(named: "CircledQuestionmark")
        }
        if employeeName == nil {
            self.employeeNameLabel.text = "No stylist assigned for this service"
        } else {
            self.employeeNameLabel.text = "Stylist: " + employeeName!
        }
        self.minLabel.hidden = hideSlider
        self.maxLabel.hidden = hideSlider
        self.amountSlider.hidden = hideSlider
        
        self.amountSlider.minimumValue = min?.floatValue ?? 0
        self.amountSlider.maximumValue = max?.floatValue ?? 0
        self.amountSlider.value = self.beforeDiscount?.floatValue ?? 0
        self.beforeDiscountLabel.text = "Price before discount " + self.stringForCurrencyAmount(self.beforeDiscount)!
        self.afterDiscountLabel.text = "Price after discount " + self.stringForCurrencyAmount(afterDiscount)!
        var segmentIndex = self.discountType!.integerValue - 1
        if segmentIndex < 0 {
            segmentIndex = 0
        }
        self.discountTypeSegmentedControl.selectedSegmentIndex = segmentIndex
        if segmentIndex == 0 {
            self.discountValueLabel.text = self.discountValue!.stringValue + "%"
        } else {
            self.discountValueLabel.text = self.stringForCurrencyAmount(self.discountValue) ?? " "
        }
        self.discountStepper.value = self.discountValue!.doubleValue
        self.minLabel.text = self.stringForCurrencyAmount(min)
        self.maxLabel.text = self.stringForCurrencyAmount(max)
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
