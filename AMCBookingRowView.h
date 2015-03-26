//
//  AMCBookingRowView.h
//  ClaudiasSalon
//
//  Created by service on 19/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
@class Appointment;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCBookingRowView : NSTableCellView <NSTableViewDelegate, NSTableViewDataSource>
@property (weak) IBOutlet NSTextField *appointmentTitleLabel;

@property (weak) IBOutlet NSTextField *appointmentStartLabel;

@property (weak) IBOutlet NSTextField *appointmentEndLabel;

@property (weak) IBOutlet NSTableView *servicesTable;

@property Appointment * appointment;
@end
