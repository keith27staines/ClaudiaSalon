//
//  AMCWizardStepBookAppointmentForCustomerViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCWizardStepViewController.h"

#import "AMCSalonDocument.h"
@interface AMCWizardStepBookAppointmentForCustomerViewController : AMCWizardStepViewController 

@property (weak) IBOutlet NSTableView *chosenServicesTable;
@property (weak) IBOutlet NSTableView *appointmentSlotsTable;

@property (weak) IBOutlet NSTextField *timeNowLabel;
@property (weak) IBOutlet NSButton *setDateTimeButton;
- (IBAction)setDateTimeToNowButtonClicked:(id)sender;
@property (weak) IBOutlet NSDatePicker *datePicker;
- (IBAction)datePickerChanged:(id)sender;
@property (weak) IBOutlet NSButton *addServiceButton;
- (IBAction)addServiceButtonClicked:(id)sender;

@property (weak) IBOutlet NSButton *removeServiceButton;
- (IBAction)removeServiceButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton *setAppointmentTimeButton;
- (IBAction)setAppointmentTimeButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton *showNotesButton;

- (IBAction)showNotesButtonClicked:(id)sender;

@property (weak) IBOutlet NSTextField *priceTotalLabel;
- (IBAction)quickQuoteButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton *quickQuoteButton;

@property (weak) IBOutlet NSTextField *dayOfWeekLabel;

@property (weak) IBOutlet NSTextField *dateLabel;

- (IBAction)showBookingViewButtonClicked:(id)sender;

@property (weak) IBOutlet NSButton *showBusyView;
- (IBAction)showBusyButtonClicked:(id)sender;

@property (weak) IBOutlet NSTextField *advancePaymentLabel;
@property (weak) IBOutlet NSButton *advancePaymentButton;


@end
