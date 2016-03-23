//
//  AppointmentFormatter.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 29/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation

class AppointmentFormatter {
    let appointment:Appointment
    init(appointment:Appointment) {
        self.appointment = appointment
    }
    var appointmentDayString: String {
        return AppointmentFormatter.dateFormatter.stringFromDate(appointment.appointmentDate!)
    }
    var verboseAppointmentDayString: String {
        guard let date = appointment.appointmentDate  else {
            return ""
        }
        return date.stringNamingDayOfWeek() + " " + self.appointmentDayString
    }
    var startTimeString: String {
        guard let date = appointment.appointmentDate  else {
            return ""
        }
        return AppointmentFormatter.timeFormatter.stringFromDate(date)
    }
    var finishTimeString: String {
        guard let date = appointment.appointmentEndDate  else {
            return ""
        }
        return  AppointmentFormatter.timeFormatter.stringFromDate(date)
    }
    
    static var dateFormatter:NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateStyle = .LongStyle
        formatter.timeStyle = .NoStyle
        return formatter
    }()
    static var timeFormatter:NSDateFormatter = { () -> NSDateFormatter in
        let formatter = NSDateFormatter()
        formatter.dateStyle = .NoStyle
        formatter.timeStyle = .ShortStyle
        return formatter
    }()
    func bookedDurationString() -> String {
        guard let interval = appointment.bookedDuration?.doubleValue else {
            return ""
        }
        let hours = Int(floor(Double(interval)/3600.0))
        let minutes = Int((interval/60.0) % 60.0)
        var duration = String()
        if hours > 1 {
            duration = "\(hours) h "
        } else if hours == 1 {
            duration = "\(hours) h "
        }
        if minutes > 1 {
            duration += "\(minutes) m "
        } else if minutes == 1 {
            duration += "\(minutes) m "
        }
        return duration
    }    
}
