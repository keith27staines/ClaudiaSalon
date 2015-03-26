//
//  AMCWizardStepSelectCustomerViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
@class AMCDayAndMonthPopupViewController;

#import "AMCWizardStepViewController.h"
#import "AMCSalonDocument.h"
@interface AMCWizardStepSelectCustomerViewController : AMCWizardStepViewController <NSTableViewDataSource, NSTableViewDelegate, NSControlTextEditingDelegate,NSTextFieldDelegate>

@property (weak) IBOutlet NSButton * clearAllFields;

@property (weak) IBOutlet NSTextField *firstName;

@property (weak) IBOutlet NSTextField *lastName;

@property (weak) IBOutlet NSTextField *phone;

@property (weak) IBOutlet NSTextField *email;

@property (weak) IBOutlet NSTextField *postcode;

@property (weak) IBOutlet NSTextField *addressLine1;

@property (weak) IBOutlet NSTextField *addressLine2;

@property (weak) IBOutlet NSTextField *instructionLabel;

@property (weak) IBOutlet NSTableView *customersTable;

@property (weak) IBOutlet NSButton *createCustomerButton;

@property (strong) IBOutlet AMCDayAndMonthPopupViewController *dayAndMonthContoller;

- (IBAction)createCustomer:(id)sender;
-(IBAction)clearAllFields:(id)sender;
@end
