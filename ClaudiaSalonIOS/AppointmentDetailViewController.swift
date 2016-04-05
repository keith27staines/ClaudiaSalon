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
    
    var appointmentWasUpdated:((appointment:Appointment)->Void)?
    
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func saleItemWasUpdated(saleItem:SaleItem) {
        self.configureView()
        self.updateAppointment(saleItem.sale!.fromAppointment!)
    }

    func configureView() {

        // Update the user interface for the detail item.
        self.view.hidden = true
        guard let appointment = self.detailItem as! Appointment? else {
            return
        }
        self.view.hidden = false
        
        // Configure customer info
        self.customerFullName.text = appointment.customer?.fullName
        self.phone.text = appointment.customer?.phone
        
        // Configure appointment info
        let appointmentFormatter = AppointmentFormatter(appointment: appointment)
        self.appointmentDate.text = appointmentFormatter.verboseAppointmentDayString
        self.startTime.text = appointmentFormatter.startTimeString
        self.finishTime.text = appointmentFormatter.finishTimeString
        self.duration.text = appointmentFormatter.bookedDurationString()
        
        // Configure sale info
        let nominalCharge = appointment.sale?.nominalCharge
        let actualCharge = appointment.sale?.actualCharge
        let discountAmount = appointment.sale?.discountAmount
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
            guard let _ = appointment.sale else {
                fatalError("appointment doesn't have a sale")
            }
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
        if segue.identifier == "selectInterval" {
            guard let vc = segue.destinationViewController as? SelectTimeIntervalPopover else {
                fatalError("Unexpected destination controller for selectInterval)")
            }
            vc.configure("Duration", intervalInSeconds: appointment.bookedDuration!.integerValue, completion: changedInterval)
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
    func changedInterval(vc:SelectTimeIntervalPopover) {
        if vc.cancelled { return }
        let appointment = detailItem as! Appointment
        appointment.bookedDuration = vc.interval
        self.configureView()
        self.updateAppointment(appointment)
    }
    func changedStartTime(vc:SelectDateOrTimePopover) {
        if vc.cancelled { return }
        let appointment = detailItem as! Appointment
        appointment.appointmentDate = vc.selectedDate
        self.configureView()
        self.updateAppointment(appointment)
    }
    func changedFinishTime(vc:SelectDateOrTimePopover) {
        if vc.cancelled { return }
        let appointment = detailItem as! Appointment
        let duration = vc.selectedDate.timeIntervalSinceDate(appointment.appointmentDate!)
        appointment.bookedDuration = duration
        self.configureView()
        self.updateAppointment(appointment)
    }
    func changedAppointmentDate(vc:SelectDateOrTimePopover) {
        if vc.cancelled { return }
        let appointment = detailItem as! Appointment
        appointment.appointmentDate = vc.selectedDate
        self.configureView()
        self.updateAppointment(appointment)
    }
    func changedCustomer(vc:UIViewController) {
        if let vc = vc as? FindCustomerViewController {
            let appointment = detailItem as! Appointment
            guard let selectedCustomerObjectID = vc.selectedCustomer?.objectID else {
                return
            }
            if appointment.customer?.objectID != selectedCustomerObjectID {
                let moc = Coredata.sharedInstance.managedObjectContext
                appointment.customer = moc.objectWithID(selectedCustomerObjectID) as? Customer
                self.configureView()
            }
            self.updateAppointment(appointment)
        }
    }
    func updateAppointment(appointment:Appointment) {
        if let callback = self.appointmentWasUpdated  {
            appointment.cascadeHasChangesUpdwards()
            callback(appointment: appointment)
        }
    }
}























