//
//  AMCAppointmentsViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 23/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
@class EditObjectViewController;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
#import "AMCAppointmentsView.h"
#import "AMCWizardWindowController.h"

@interface AMCAppointmentsViewController : AMCViewController 
@property (weak) IBOutlet NSSegmentedControl *intervalPickerSegmentedControl;

- (IBAction)intervalChanged:(id)sender;
@property (weak) IBOutlet NSTableView *appointmentsTable;
@property (weak) IBOutlet NSTableView *saleItemsTable;

@property (weak) IBOutlet NSButton *createAppointmentButton;
@property (weak) IBOutlet NSButton *editAppointmentButton;
@property (weak) IBOutlet NSButton *completeAppointmentButton;
@property (weak) IBOutlet NSButton *cancelAppointmentButton;
@property (weak) IBOutlet NSButton *viewCustomerButton;

- (IBAction)createNewAppointment:(id)sender;
- (IBAction)editAppointment:(id)sender;
- (IBAction)cancelAppointment:(id)sender;
- (IBAction)completeAppointment:(id)sender;
- (IBAction)viewCustomer:(id)sender;

@property (strong) IBOutlet EditObjectViewController *editCustomerViewController;
- (IBAction)showNotesButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton *showNotesButton;
@property (weak) IBOutlet NSTextField *totalLabel;
@property (weak) IBOutlet NSButton *showQuickQuoteButton;
- (IBAction)showQuickQuoteButtonClicked:(id)sender;

@property (weak) IBOutlet NSPopUpButton *appointmentStateSelectorButton;

- (IBAction)appointmentStateSelectorChanged:(id)sender;

@property (weak) IBOutlet NSSearchField *searchField;

- (IBAction)searchFieldChanged:(id)sender;



@end
