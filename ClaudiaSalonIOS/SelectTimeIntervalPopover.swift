//
//  SelectTimeIntervalPopover.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 05/04/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class SelectTimeIntervalPopover : UIViewController, UIPickerViewDataSource,UIPickerViewDelegate {
    
    private (set) var completion: ((vc:SelectTimeIntervalPopover)->Void)?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var picker: UIPickerView!
    var interval:Int = 1*3600 + 20 * 60
    var cancelled = false
    
    @IBAction func cancelTapped() {
        self.closeController(true)
    }
    
    @IBAction func doneTapped(sender: AnyObject) {
        self.closeController(false)
    }
    private func closeController(cancel:Bool) {
        self.cancelled = cancel
        if !cancel {
            self.interval = self.picker.selectedRowInComponent(0)*3600 + self.picker.selectedRowInComponent(1) * 5 * 60
            if let completionCallback = self.completion {
                completionCallback(vc: self)
            }
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.setPickerFromInterval()
        self.titleLabel.text = self.title
    }
    func configure(title:String,intervalInSeconds:Int, completion:((vc:SelectTimeIntervalPopover)->Void)?) {
        self.title = title
        self.completion = completion
        self.cancelled = false
        self.interval = intervalInSeconds
        self.setPickerFromInterval()
    }
    func setPickerFromInterval() {
        if let picker = self.picker {
            let hours = interval / 3600
            let mins = (interval % 3600) / 60
            let fiveMins = mins / 5
            picker.selectRow(hours, inComponent: 0, animated: false)
            picker.selectRow(fiveMins, inComponent: 1, animated: false)
        }
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 11
        } else {
            return 12
        }
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return String(row) + " hours"
        }
        if component == 1 {
            return String(format: ":%2d mins", 5*row)
        }
        return ""
    }
}
