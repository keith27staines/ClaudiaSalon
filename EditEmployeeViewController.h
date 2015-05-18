//
//  EditEmployeeWindowController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
#import "EditObjectViewController.h"
#import "AMCDayAndMonthPopupViewController.h"

@interface EditEmployeeViewController :EditObjectViewController <AMCDayAndMonthPopupViewControllerDelegate>

@property (weak) IBOutlet NSTextField * firstName;
@property (weak) IBOutlet NSTextField * lastName;
@property (weak) IBOutlet NSTextField * email;
@property (weak) IBOutlet NSTextField * mobile;

@property (weak) IBOutlet AMCDayAndMonthPopupViewController * dayAndMonthPopupController;

@property (weak) IBOutlet NSTextField *postcode;
@property (weak) IBOutlet NSTextField *addressLine1;

@property (weak) IBOutlet NSTextField *addressLine2;

@property (weak) IBOutlet NSButton *activeMemberOfStaffCheckbox;

@end
