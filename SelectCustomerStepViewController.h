//
//  SelectCustomerStepViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 27/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
@class AMCDayAndMonthPopupViewController, Customer, AMCDayAndMonthPopupViewController;
#import "AMCSalonDocument.h"
#import "WizardStepViewController.h"
#import "AMCDayAndMonthPopupViewController.h"

@interface SelectCustomerStepViewController : WizardStepViewController <NSTableViewDataSource, NSTableViewDelegate, NSControlTextEditingDelegate,NSTextFieldDelegate>

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

@property (weak) IBOutlet NSButton *clearButton;

@end
