//
//  AppointmentViewCellTableViewCell.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 27/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import UIKit

class AppointmentViewCellTableViewCell: UITableViewCell {
    
    @IBOutlet weak var customerNameLabel: UILabel!
    
    @IBOutlet weak var startTimeLabel: UILabel!
    
    @IBOutlet weak var durationLabel: UILabel!
    
    @IBOutlet weak var finishTimeLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    var appointment:Appointment! {
        didSet {
            let formatter = AppointmentFormatter(appointment: self.appointment!)
            let hasChanges = self.appointment.bqHasClientChanges?.boolValue ?? false
            let needsExport = self.appointment.bqNeedsCoreDataExport?.boolValue ?? false
            let needsImport = self.appointment.bqNeedsCloudImport?.boolValue ?? false
            
            self.customerNameLabel.text = self.appointment.customer?.fullName ?? ""
            self.dateLabel.text = formatter.verboseAppointmentDayString
            self.startTimeLabel.text = "Start " + formatter.startTimeString
            self.finishTimeLabel.text = "Finish " + formatter.finishTimeString
            self.durationLabel.text = formatter.bookedDurationString()
            let button = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            var image:UIImage
            
            if needsImport {
                image = UIImage(named: "red-cloud")!
            } else {
                if hasChanges {
                    image = UIImage(named: "amber-cloud")!
                } else if needsExport {
                    image = UIImage(named: "blue-cloud")!
                } else {
                    image = UIImage(named: "green-cloud")!
                }
            }
            
            button.setImage(image, forState: UIControlState.Normal)
            button.imageView?.contentMode = .ScaleAspectFit
            button.addTarget(self, action: #selector(AppointmentViewCellTableViewCell.accessoryButtonTapped(_:event:)), forControlEvents: UIControlEvents.TouchUpInside)
            self.accessoryView = button
        }
    }
    
    var cloudSynchButtonTapped:((appointment:Appointment)->Void)?

    func accessoryButtonTapped(button:UIControl, event:UIEvent) {
        if let callback = cloudSynchButtonTapped {
            callback(appointment: self.appointment)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    

}
