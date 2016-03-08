//
//  AppointmentDetailViewController.swift
//  ClaudiaSalonIOS
//
//  Created by Keith Staines on 21/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit
import CloudKit

class AppointmentDetailViewController: UITableViewController,SaleItemUpdateReceiver {

    @IBOutlet weak var customerFullName: UILabel!
    
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var appointmentDate: UILabel!
    
    @IBOutlet weak var startTime: UILabel!
    
    @IBOutlet weak var finishTime: UILabel!
    
    @IBOutlet weak var duration: UILabel!
    
    @IBOutlet weak var nominalCharge: UILabel!
    
    @IBOutlet weak var discountAmount: UILabel!
    
    @IBOutlet weak var actualCharge: UILabel!
    
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func saleItemWasUpdated(saleItem:SaleItem) {
        saleItem.managedObjectContext?.performBlock() {
            saleItem.sale?.updatePriceFromSaleItems()
            Coredata.sharedInstance.saveContext()
            NSOperationQueue.mainQueue().addOperationWithBlock() {
                self.configureView()
            }
        }
    }

    func configureView() {

        // Update the user interface for the detail item.
        self.view.hidden = true
        guard let appointment = self.detailItem as! Appointment? else {
            return
        }
        self.view.hidden = false
        var fullName: String?
        var phone: String?
        var nominalCharge: NSNumber?
        var actualCharge: NSNumber?
        var discountAmount: NSNumber?
        appointment.managedObjectContext?.performBlockAndWait() {
            fullName = appointment.customer?.fullName
            phone = appointment.customer?.phone
            nominalCharge = appointment.sale?.nominalCharge
            actualCharge = appointment.sale?.actualCharge
            discountAmount = appointment.sale?.discountAmount
        }
        
        // Configure customer info
        self.customerFullName.text = fullName
        self.phone.text = phone
        
        // Configure appointment info
        let appointmentFormatter = AppointmentFormatter(appointment: appointment)
        self.appointmentDate.text = appointmentFormatter.verboseAppointmentDayString
        self.startTime.text = appointmentFormatter.startTimeString
        self.finishTime.text = appointmentFormatter.finishTimeString
        self.duration.text = appointmentFormatter.bookedDurationString()
        
        // Configure sale info
        self.nominalCharge.text = stringForCurrencyAmount(nominalCharge) ?? "?"
        self.actualCharge.text = stringForCurrencyAmount(actualCharge) ?? "?"
        self.discountAmount.text = stringForCurrencyAmount(discountAmount) ?? "?"
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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard let appointment = detailItem as? Appointment else {
            fatalError("detail item is not an appointment")
        }
        if segue.identifier == "saleItems" {
            guard let vc = segue.destinationViewController as? SaleDetailViewController else {
                fatalError("Unexpected destination controller for saleItems)")
            }
            vc.delegate = self
            guard let sale = appointment.sale else {
                fatalError("appointment doesn't have a sale")
            }
            let container = CKContainer(identifier: "iCloud.uk.co.ClaudiasSalon.ClaudiaSalon")
            let publicDatabase = container.publicCloudDatabase
            let saleItemOperation = SaleItemsForSaleOperation(sale: sale)
            publicDatabase.addOperation(saleItemOperation)
            vc.saleID = appointment.sale!.objectID
            return
        }
        if segue.identifier == "saleDetail" {
            return
        }
        if segue.identifier == "customer" {
            guard let vc = segue.destinationViewController as? FindCustomerViewController else {
                fatalError("Unexpected destination controller for customer")
            }
            vc.selectedCustomer = appointment.customer
            vc.completion = changedCustomer
            return
        }
        if segue.identifier == "selectStartTime" {
            guard let vc = segue.destinationViewController as? SelectDateOrTimePopover else {
                fatalError("Unexpected destination controller for selectFinishTime)")
            }
            vc.configure("Choose appointment start time",selectedDate: appointment.appointmentDate!, minDate: appointment.appointmentDate!.beginningOfDay(), maxDate: appointment.appointmentEndDate!, mode: UIDatePickerMode.Time, completion: changedStartTime)
            return
        }
        if segue.identifier == "selectFinishTime" {
            guard let vc = segue.destinationViewController as? SelectDateOrTimePopover else {
                fatalError("Unexpected destination controller for selectFinishTime)")
            }
            vc.configure("Choose appointment finish time",selectedDate: appointment.appointmentEndDate!, minDate: appointment.appointmentDate!, maxDate: appointment.appointmentDate!.endOfDay(), mode: UIDatePickerMode.Time, completion: changedFinishTime)
            return
        }
        if segue.identifier == "selectDate" {
            guard let vc = segue.destinationViewController as? SelectDateOrTimePopover else {
                fatalError("Unexpected destination controller for selectDate)")
            }
            vc.configure("Choose appointment day",selectedDate: appointment.appointmentDate!, minDate: NSDate(), maxDate: NSDate.distantFuture(), mode: UIDatePickerMode.Date, completion: changedAppointmentDate)
            return
        }
        
    }
    func changedStartTime(vc:SelectDateOrTimePopover) {
        if vc.cancelled { return }
        let appointment = detailItem as! Appointment
        appointment.appointmentDate = vc.selectedDate
        self.configureView()
    }
    func changedFinishTime(vc:SelectDateOrTimePopover) {
        if vc.cancelled { return }
        let appointment = detailItem as! Appointment
        let duration = vc.selectedDate.timeIntervalSinceDate(appointment.appointmentDate!)
        appointment.bookedDuration = duration
        self.configureView()
    }
    func changedAppointmentDate(vc:SelectDateOrTimePopover) {
        if vc.cancelled { return }
        let appointment = detailItem as! Appointment
        appointment.appointmentDate = vc.selectedDate
        self.configureView()
    }
    func changedCustomer(vc:UIViewController) {
        if let vc = vc as? FindCustomerViewController {
            let appointment = detailItem as! Appointment
            guard let selectedCustomerObjectID = vc.selectedCustomer?.objectID else {
                return
            }
            if appointment.customer?.objectID != selectedCustomerObjectID {
                let moc = appointment.managedObjectContext!
                moc.performBlockAndWait() {
                    appointment.customer = moc.objectWithID(selectedCustomerObjectID) as? Customer
                }
                self.configureView()
            }
        }
    }
}























