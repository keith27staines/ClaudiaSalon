//
//  BQDataExtractViewController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Cocoa
import CloudKit

class BQDataExtractViewController: NSViewController, BQFirstExtractControllerDelegate {
    
    @IBOutlet weak var customerProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var employeeProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var serviceCategoryProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var serviceProgressIndicator: NSProgressIndicator!
    @IBOutlet weak var activityIndicator: NSProgressIndicator!
   
    @IBOutlet weak var appointmentProgressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var extractStatus: NSTextField!
    var salonDocument: AMCSalonDocument!
    var extractModel : BQFirstExtractController!

    // MARK:- UI functions
    override func viewDidLoad() {
        super.viewDidLoad()
        self.activityIndicator.hidden = true
        self.extractStatus.stringValue = ""
        extractModel = BQFirstExtractController(salonDocument:self.salonDocument)
        extractModel.delegate = self
        self.salonDocument.suspendImportsAndExports(true)
    }

    @IBAction func deleteCloudNotifications(sender: AnyObject) {
        self.salonDocument.suspendImportsAndExports(true)
        self.salonDocument.deleteSubscriptions()
    }

    @IBAction func resetDataExtract(sender: AnyObject) {
        self.activityIndicator.hidden = false
        self.activityIndicator.startAnimation(self)
        self.extractModel.resetDataExtract()
        self.activityIndicator.stopAnimation(self)
        self.activityIndicator.hidden = true
    }
    @IBAction func performExtractButtonClicked(sender: AnyObject) {
        self.activityIndicator.hidden = false
        self.activityIndicator.startAnimation(self)
        self.zeroUIProgressbars()
        self.extractModel.extractData()
    }
    
    // Prepare UI for extract
    func zeroUIProgressbars() {
        // Customer
        customerProgressIndicator.minValue = 0
        customerProgressIndicator.maxValue = 100
        customerProgressIndicator.doubleValue = 0
        // Employee
        employeeProgressIndicator.minValue = 0
        employeeProgressIndicator.maxValue = 100
        employeeProgressIndicator.doubleValue = 0
        // ServiceCategory
        serviceCategoryProgressIndicator.minValue = 0
        serviceCategoryProgressIndicator.maxValue = 100
        serviceCategoryProgressIndicator.doubleValue = 0
        // Service
        serviceProgressIndicator.minValue = 0
        serviceProgressIndicator.maxValue = 100
        serviceProgressIndicator.doubleValue = 0
        // Appointment
        appointmentProgressIndicator.minValue = 0
        appointmentProgressIndicator.maxValue = 100
        appointmentProgressIndicator.doubleValue = 0
    }

    // MARK:- BQExtractModelDelegate Implementation
    func fullCoredataExtractWasCompleted(sender:AnyObject) {
        self.activityIndicator.stopAnimation(self)
        self.activityIndicator.hidden = true
    }
    func coredataRecordWasExtracted(sender:AnyObject, recordType:String, extractCount: Int, total: Int) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            let type = recordType
            var progressIndicator: NSProgressIndicator?
            switch type {
            case ICloudRecordType.Appointment.rawValue:
                progressIndicator = self.appointmentProgressIndicator
            case ICloudRecordType.Customer.rawValue:
                progressIndicator = self.customerProgressIndicator
            case ICloudRecordType.Employee.rawValue:
                progressIndicator = self.employeeProgressIndicator
            case ICloudRecordType.Service.rawValue:
                progressIndicator = self.serviceProgressIndicator
            case ICloudRecordType.ServiceCategory.rawValue:
                progressIndicator = self.serviceCategoryProgressIndicator
            case ICloudRecordType.Appointment.rawValue:
                progressIndicator = self.appointmentProgressIndicator
            case ICloudRecordType.Salon.rawValue:
                break
            default:
                break
            }
            progressIndicator?.minValue = 0
            progressIndicator?.maxValue = Double(total)
            progressIndicator?.doubleValue = Double(extractCount)
        }
    }
}
