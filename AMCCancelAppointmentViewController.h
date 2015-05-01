//
//  AMCCancelAppointmentViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 30/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
@class Appointment, AMCCancelAppointmentViewController;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"

@interface AMCCancelAppointmentViewController : AMCViewController


@property (weak) IBOutlet NSPopUpButton *cancellationTypePopupButton;
- (IBAction)cancellationTypeChanged:(id)sender;
@property (weak) IBOutlet NSTextField *explanationText;
@property (weak) IBOutlet NSButton *noButton;
@property (weak) IBOutlet NSButton *yesButton;
- (IBAction)noButtonClicked:(id)sender;
- (IBAction)yesButtonClicked:(id)sender;

@property Appointment * appointment;
@property (weak) IBOutlet NSTextField *titleField;
-(void)reloadData;
@end
