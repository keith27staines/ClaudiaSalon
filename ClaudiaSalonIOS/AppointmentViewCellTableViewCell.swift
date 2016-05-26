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
    
    @IBOutlet weak var statusLabel: UILabel!
    
    var appointment:Appointment! {
        didSet {
            let formatter = AppointmentFormatter(appointment: self.appointment!)
            let hasChanges = self.appointment.bqHasClientChanges?.boolValue ?? false
            let needsExport = self.appointment.bqNeedsCoreDataExport?.boolValue ?? false
            let needsImport = self.appointment.bqNeedsCloudImport?.boolValue ?? false
            let completed = self.appointment.completed?.boolValue ?? false
            let cancelled = self.appointment.cancelled?.boolValue ?? false
            let existsOnServer = self.appointment.bqCloudID ?? ""
            let isReadyForExport = self.appointment.isReadyForExport()
            
            let tint:UIColor
            if cancelled || completed {
                tint = UIColor(red: 0.6, green: 0.0, blue: 0.0, alpha: 1.0)
            } else {
                tint = UIColor(red: 0.0, green: 0.0, blue: 0.6, alpha: 1.0)
            }
            self.statusLabel.textColor = tint
            self.customerNameLabel.text = self.appointment.customer?.fullName ?? ""
            self.dateLabel.text = formatter.verboseAppointmentDayString
            self.startTimeLabel.text = "Start " + formatter.startTimeString
            self.finishTimeLabel.text = "Finish " + formatter.finishTimeString
            self.durationLabel.text = formatter.bookedDurationString()
            let button = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            var image:UIImage
            
            if needsImport {
                image = UIImage(named: "red-cloud")!
            } else {
                if hasChanges {
                    switch isReadyForExport {
                    case .Yes:
                        image = UIImage(named: "amber-cloud")!
                    default:
                        image = UIImage(named: "red-cloud")!
                    }
                } else if needsExport {
                    image = UIImage(named: "blue-cloud")!
                } else {
                    image = UIImage(named: "green-cloud")!
                }
            }
            
            if cancelled {
                self.statusLabel.text = "Cancelled"
            } else if completed {
                self.statusLabel.text = "Completed"
            } else {
                if existsOnServer.isEmpty {
                    self.statusLabel.text = "Preparing"
                } else {
                    self.statusLabel.text = "Booked"
                }
            }
            
            button.setImage(image, forState: UIControlState.Normal)
            button.imageView?.contentMode = .ScaleAspectFit
            button.addTarget(self, action: #selector(AppointmentViewCellTableViewCell.accessoryButtonTapped(_:event:)), forControlEvents: UIControlEvents.TouchUpInside)
            self.accessoryView = button
        }
    }
    
    var cloudSynchButtonTapped:((appointment:Appointment, button:UIButton)->Void)?

    func accessoryButtonTapped(button:UIControl, event:UIEvent) {
        if let callback = cloudSynchButtonTapped {
            let button = button as! UIButton
            callback(appointment: self.appointment, button: button)
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
