//
//  AppointmentBuilderProtocol.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 30/06/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Foundation

// MARK:- AppointmentBuilder
protocol AppointmentBuilder {
    var error: NSError? { get }
    var appointment: Appointment? { get }
}