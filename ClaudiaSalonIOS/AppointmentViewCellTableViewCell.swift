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
            self.customerNameLabel.text = appointment.customer?.fullName ?? "Keith Staines"
            let date = appointment.appointmentDate!
            let dateString = self.dateFormatter.stringFromDate(date)
            self.dateLabel.text = date.stringNamingDayOfWeek() + " " + dateString
            let startTime = self.timeFormatter.stringFromDate(self.appointment.appointmentDate!)
            let finishTime = self.timeFormatter.stringFromDate(self.appointment.appointmentEndDate!)
            self.startTimeLabel.text = "Start " + startTime
            self.finishTimeLabel.text = "Finish " + finishTime
            self.durationLabel.text = self.durationString()
            
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
    
    lazy var dateFormatter:NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        formatter.timeStyle = .NoStyle
        return formatter
    }()
    lazy var timeFormatter:NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateStyle = .NoStyle
        formatter.timeStyle = .ShortStyle
        return formatter
    }()
    
    func durationString() -> String {
        let interval = appointment.bookedDuration!.doubleValue
        let hours = Int(floor(Double(interval)/3600.0))
        let minutes = Int((interval/60.0) % 60.0)
        var duration = String()
        if hours > 1 {
            duration = "\(hours) hours "
        } else if hours == 1 {
            duration = "\(hours) hour "
        }
        if minutes > 1 {
            duration = "\(minutes) minutes"
        } else if hours == 1 {
            duration = "\(minutes) minute "
        }
        return duration
    }
}
