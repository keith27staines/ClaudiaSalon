//
//  AppointmentDetailViewController.swift
//  ClaudiaSalonIOS
//
//  Created by Keith Staines on 21/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class AppointmentDetailViewController: UITableViewController {

    @IBOutlet weak var customerFullName: UILabel!
    
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var appointmentDate: UILabel!
    
    @IBOutlet weak var startTime: UILabel!
    
    @IBOutlet weak var finishTime: UILabel!
    
    @IBOutlet weak var duration: UILabel!
    
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        self.view.hidden = true
        guard let appointment = self.detailItem as! Appointment? else {
            return
        }
        self.view.hidden = false
        if let customer = appointment.customer {
            self.customerFullName.text = appointment.customer!.fullName!
            self.phone.text = customer.phone
        }

        let appointmentFormatter = AppointmentFormatter(appointment: appointment)
        self.appointmentDate.text = appointmentFormatter.verboseAppointmentDayString
        self.startTime.text = appointmentFormatter.startTimeString
        self.finishTime.text = appointmentFormatter.finishTimeString
        self.duration.text = appointmentFormatter.bookedDurationString()
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


}

