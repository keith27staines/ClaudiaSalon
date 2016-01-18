//
//  MakePaymentStepViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 27/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class AMCReceiptWindowController;
#import "AMCSalonDocument.h"
#import "WizardStepViewController.h"
#import "AMCPaymentCompleteWindowController.h"
#import "AMCCashEntryField.h"

@interface MakePaymentStepViewController : WizardStepViewController <NSControlTextEditingDelegate,NSTextFieldDelegate, AMCCashEntryDelegate>

@property (weak) IBOutlet NSTextField *costOfAllWithoutAdditionalDiscount;

@property (weak) IBOutlet NSTextField *costAfterIndividualDiscounts;

@property (weak) IBOutlet NSPopUpButton *additionalDiscountPopup;

@property (weak) IBOutlet NSTextField *totalDiscount;
- (IBAction)discountTypeChanged:(id)sender;

@property (weak) IBOutlet NSSegmentedControl *discountTypeSegmentedControl;

@property (weak) IBOutlet NSTextField *totalToPay;

@property (weak) IBOutlet AMCCashEntryField *amountGivenByCustomer;

@property (weak) IBOutlet NSTextField *changeToReturn;

@property (weak) IBOutlet NSButton *paymentCompleteButton;

@property (weak) IBOutlet NSButton *saveAsQuoteButton;

- (IBAction)extraDiscountChanged:(id)sender;

- (IBAction)amountGivenByCustomerFieldChanged:(id)sender;
@property (weak) IBOutlet NSTextField *alreadyPaid;

- (IBAction)paymentComplete:(id)sender;

- (IBAction)saveAsQuote:(id)sender;

@property (strong) IBOutlet AMCPaymentCompleteWindowController *paymentCompleteWindowController;

@property (weak) IBOutlet NSSegmentedControl *cardCashSegmentedControl;

- (IBAction)cardCashSegmentedControlChanged:(id)sender;



@property BOOL receiptRequired;
@end
