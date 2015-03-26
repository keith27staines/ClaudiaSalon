//
//  AMCHoursWorkedOnDayViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCHoursWorkedOnDayViewController : AMCViewController

@property NSDate * date;
@property BOOL worked;
@property double hoursWorked;
@end
