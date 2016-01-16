//
//  EditSaleViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 27/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class Sale, AMCReceiptWindowController;

#import "EditObjectViewController.h"
#import "AMCWizardStepDelegate.h"
#import "AMCReceiptWindowController.h"

@interface EditSaleViewController : EditObjectViewController <AMCWizardStepDelegate>


@property (weak) IBOutlet NSButton *previousStep;

@property (weak) IBOutlet NSButton *nextStep;

- (IBAction)previousStep:(id)sender;

- (IBAction)nextStep:(id)sender;
@property (weak) IBOutlet NSTextField *selectCustomerLabel;
@property (weak) IBOutlet NSTextField *chooseItemsLabel;
@property (weak) IBOutlet NSTextField *takePaymentLabel;
@property (weak) IBOutlet NSView *wizardStepContainerView;
@property (strong) IBOutlet AMCReceiptWindowController *receiptPrinterWindowController;

@property BOOL customerSelected;
@property BOOL itemsSelected;
@property BOOL paymentMade;

@property (weak) IBOutlet WizardStepViewController *selectCustomerViewController;

@property (weak) IBOutlet WizardStepViewController *selectItemsViewController;

@property (weak) IBOutlet WizardStepViewController *makePaymentViewController;

-(void)clear;
@property (readonly) Sale * sale;
@end
