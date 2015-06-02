//
//  AMCStaffBusyViewController.h
//  ClaudiasSalon
//
//  Created by service on 21/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
@class AMCStaffBusyView;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCStaffBusyViewController : AMCViewController
@property (weak) IBOutlet AMCStaffBusyView *staffBusyView;

@property (copy) NSDate * startDate;
@property (copy) NSDate * endDate;
@end
