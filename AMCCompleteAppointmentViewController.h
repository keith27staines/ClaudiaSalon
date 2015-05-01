//
//  AMCCompleteAppointmentViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 31/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class Appointment, AMCCompleteAppointmentViewController;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"

@interface AMCCompleteAppointmentViewController : AMCViewController

@property (weak) IBOutlet NSPopUpButton *operationTypePopupButton;
- (IBAction)operationTypeChanged:(id)sender;
@property (weak) IBOutlet NSTextField *explanationText;
@property (weak) IBOutlet NSButton *noButton;
@property (weak) IBOutlet NSButton *yesButton;
- (IBAction)noButtonClicked:(id)sender;
- (IBAction)yesButtonClicked:(id)sender;

@property Appointment * appointment;

@end
