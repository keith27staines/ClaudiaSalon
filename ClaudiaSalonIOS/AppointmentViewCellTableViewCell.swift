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
            var fullName = ""
            var dateString = ""
            var startTime = ""
            var finishTime = ""
            var durationString = ""
            var hasChanges = false
            var needsExport = false
            appointment.managedObjectContext?.performBlockAndWait() {
                let formatter = AppointmentFormatter(appointment: self.appointment!)
                fullName = self.appointment.customer?.fullName ?? ""
                dateString = formatter.verboseAppointmentDayString
                startTime = formatter.startTimeString
                finishTime = formatter.finishTimeString
                durationString = formatter.bookedDurationString()
                hasChanges = self.appointment.bqHasClientChanges?.boolValue ?? false
                needsExport = self.appointment.bqNeedsCoreDataExport?.boolValue ?? false
                
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    self.customerNameLabel.text = fullName
                    self.dateLabel.text = dateString
                    self.startTimeLabel.text = "Start " + startTime
                    self.finishTimeLabel.text = "Finish " + finishTime
                    self.durationLabel.text = durationString
                    let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                    var image:UIImage
                    if hasChanges {
                        button.tintColor = UIColor.orangeColor()
                        image = UIImage(named: "amber-cloud")!
                    } else if needsExport {
                        button.tintColor = UIColor.blueColor()
                        image = UIImage(named: "blue-cloud")!
                    } else {
                        button.tintColor = UIColor.greenColor()
                        image = UIImage(named: "green-cloud")!
                    }
                    button.setImage(image, forState: UIControlState.Normal)
                    button.imageView?.contentMode = .ScaleAspectFit
                    button.addTarget(self, action: #selector(AppointmentViewCellTableViewCell.accessoryButtonTapped(_:event:)), forControlEvents: UIControlEvents.TouchUpInside)
                    self.accessoryView = button
                }
            }
        }
    }
    
    var cloudSynchButtonTapped:((appointment:Appointment)->Void)?

    func accessoryButtonTapped(button:UIControl, event:UIEvent) {
        if let callback = cloudSynchButtonTapped {
            callback(appointment: self.appointment)
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
