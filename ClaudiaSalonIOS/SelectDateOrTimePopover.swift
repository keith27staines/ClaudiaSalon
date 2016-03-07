//
//  SelectDateOrTimePopover.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 07/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class SelectDateOrTimePopover : UIViewController {

    @IBOutlet weak var titleLabel:UILabel!
    @IBOutlet weak var datePicker:UIDatePicker!
    
    private (set) var completion: ((vc:SelectDateOrTimePopover)->Void)?
    private (set) var datePickerMode: UIDatePickerMode!
    private (set) var minimumDate:NSDate!
    private (set) var maximumDate:NSDate!
    private (set) var selectedDate:NSDate!
    var cancelled = false
    
    @IBAction func cancelTapped() {
        self.closeController(true)
    }
    
    @IBAction func doneTapped(sender: AnyObject) {
        self.closeController(false)
    }
    private func closeController(cancel:Bool) {
        self.cancelled = cancel
        self.selectedDate = self.datePicker.date
        guard let completionCallback = self.completion else {
            return
        }
        completionCallback(vc: self)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.reload()
    }
    func configure(title:String,selectedDate:NSDate, minDate:NSDate, maxDate:NSDate,mode:UIDatePickerMode, completion:((vc:SelectDateOrTimePopover)->Void)?) {
        self.title = title
        self.completion = completion
        self.selectedDate = selectedDate
        self.minimumDate = minDate
        self.maximumDate = maxDate
        self.datePickerMode = mode
        self.cancelled = false
    }
    private func reload() {
        self.titleLabel.text = self.title
        self.datePicker.datePickerMode = self.datePickerMode
        self.datePicker.minimumDate = self.minimumDate
        self.datePicker.maximumDate = self.maximumDate
        self.datePicker.date = self.selectedDate
    }
}