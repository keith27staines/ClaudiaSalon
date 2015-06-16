//
//  AMCAppointmentViewer.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 16/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

@class Appointment, Sale, Customer;
#import "AMCViewController.h"
typedef NS_ENUM(NSInteger, AMCAppointmentViews) {
    AMCAppointmentViewAppointment,
    AMCAppointmentViewSale,
    AMCAppointmentViewCustomer,
};
@interface AMCAppointmentViewer : AMCViewController
@property AMCAppointmentViews selectedView;
@property Appointment * appointment;
@property Sale * sale;
@property Customer * customer;
@end
