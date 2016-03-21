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
                let hasChanges = self.appointment.bqHasClientChanges?.boolValue ?? false
                let needsExport = self.appointment.bqNeedsCoreDataExport?.boolValue ?? false
                
                NSOperationQueue.mainQueue().addOperationWithBlock() {
                    self.customerNameLabel.text = fullName
                    self.dateLabel.text = dateString
                    self.startTimeLabel.text = "Start " + startTime
                    self.finishTimeLabel.text = "Finish " + finishTime
                    self.durationLabel.text = durationString
                    let button = UIButton(type: UIButtonType.Custom)
                    let image = UIImage(named: "cloud-upload")
                    button.imageView?.image = image
                    button.addTarget(self, action: "accessoryButtonTapped:event:", forControlEvents: UIControlEventTouchUpInside)
                    self.accessoryView = UIButton()
                    
                    if hasChanges {
                        self.accessoryView?.tintColor = UIColor.orangeColor()
                    } else if needsExport {
                        self.accessoryView?.tintColor = UIColor.blueColor()
                    } else {
                        self.accessoryView?.tintColor = UIColor.greenColor()
                    }
                    
                }
            }
        }
    }
    func accessoryButtonTapped(button:UIControl, event:UIEvent) {
        var hasChanges:Bool?
        var needsExport:Bool?
        Coredata.sharedInstance.backgroundContext.performBlockAndWait() {
            hasChanges = self.appointment.bqHasClientChanges?.boolValue ?? false
            needsExport = self.appointment.bqNeedsCoreDataExport?.boolValue ?? false
        }
        NSOperationQueue.mainQueue().addOperationWithBlock() {
            if hasChanges! {
                let alert = UIAlertController(title: "Synch changes?", message: "Tap 'export' if you are ready to synch this appointment with the cloud", preferredStyle: .ActionSheet)
                let exportAction = UIAlertAction(title: "Export", style: .Default) { action in
                    
                }
                let cancelAction = UIAlertAction(title: "Not yet", style: .Cancel) { action in
                    
                }
                alert.addAction(exportAction)
                alert.addAction(cancelAction)
                self..presentViewController(alert, animated: true, completion: nil)
            } else if needsExport! {
                let alert = UIAlertController(title: "Synching", message: "This appointment's changes are being synched to the cloud", preferredStyle: .ActionSheet)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alert.addAction(okAction)
                self.presentViewController(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Already synched", message: "This appointment is already synched with the cloud", preferredStyle: .ActionSheet)
                let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alert.addAction(okAction)
                self.presentViewController(alert, animated: true, completion: nil)
            }
            
        }
    }
//    - (void) accessoryButtonTapped: (UIControl *) button withEvent: (UIEvent *) event
//    {
//    NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint: [[[event touchesForView: button] anyObject] locationInView: self.tableView]];
//    if ( indexPath == nil )
//    return;
//    
//    [self.tableView.delegate tableView: self.tableView accessoryButtonTappedForRowWithIndexPath: indexPath];
//    }
//    
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
