//
//  AppointmentViewCellTableViewCell.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 27/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class AppointmentViewCellTableViewCell: UITableViewCell {
    var appointment:Appointment! {
        didSet {
            appointment.managedObjectContext?.performBlock() {
                let formatter = AppointmentFormatter(appointment: self.appointment!)
                let fullName = self.appointment.customer?.fullName
                let dateString = formatter.verboseAppointmentDayString
                let startTime = formatter.startTimeString
                let finishTime = formatter.finishTimeString
                let durationString = formatter.bookedDurationString()
                
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    self.customerNameLabel.text = fullName
                    self.dateLabel.text = dateString
                    self.startTimeLabel.text = "Start " + startTime
                    self.finishTimeLabel.text = "Finish " + finishTime
                    self.durationLabel.text = durationString
                }
            }
        }
    }
    
    @IBOutlet weak var customerNameLabel: UILabel!
    @IBOutlet weak var startTimeLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var finishTimeLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

}
