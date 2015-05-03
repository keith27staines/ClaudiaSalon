//
//  EditPaymentWindowController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 08/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditObjectViewController.h"
#import "AMCSalonDocument.h"
@interface EditPaymentViewController : EditObjectViewController

@property (weak) IBOutlet NSDatePicker *paymentDatePicker;

@property (weak) IBOutlet NSTextField *amountField;

@property (weak) IBOutlet NSTextField * feeField;

@property (weak) IBOutlet NSTextField *payeeField;

@property (weak) IBOutlet NSTextField *paymentReasonField;

@property (weak) IBOutlet NSButton *isRefundCheckbox;


@property (weak) IBOutlet NSPopUpButton *categoryPopup;
- (IBAction)standardSelection:(id)sender;
@property (weak) IBOutlet NSSegmentedControl *paymentDirection;

@property (weak) IBOutlet NSPopUpButton *accountPopupButton;


- (IBAction)accountPopupButtonChanged:(NSPopUpButton *)sender;

@property (weak) IBOutlet NSButton *reconciledWithBankStatementCheckbox;

- (IBAction)reconciledWithBankStatementChanged:(id)sender;


@end
