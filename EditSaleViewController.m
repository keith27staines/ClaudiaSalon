//
//  EditSaleViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 27/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditSaleViewController.h"
#import "Customer+Methods.h"
#import "Sale+Methods.h"
#import "Payment+Methods.h"
#import "MakePaymentStepViewController.h"
#import "AMCReceiptWindowController.h"
#import "AMCSalonDocument.h"

typedef NS_ENUM(NSUInteger, CreateSaleStep)
{
    CreateSaleStepFirstStep = 0,
    CreateSaleStepSelectCustomer = 0,
    CreateSaleStepSelectItems = 1,
    CreateSaleStepMakePayment = 2,
    CreateSaleStepLastStep = 2,
};

@interface EditSaleViewController ()
{
    CreateSaleStep _currentStep;
    BOOL _customerSelected;
    BOOL _itemsSelected;
    BOOL _paymentMade;
}

@property CreateSaleStep currentStep;
@property NSView * viewToDisplay;
@property Customer * customer;
@end

@implementation EditSaleViewController

-(NSString *)nibName
{
    return @"EditSaleViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.cancelButton setBezelStyle:NSRoundedBezelStyle];
    [self.previousStep setBezelStyle:NSRoundedBezelStyle];
    [self.nextStep setBezelStyle:NSRoundedBezelStyle];
    [self.doneButton setBezelStyle:NSRoundedBezelStyle];
    [self.cancelButton setBezelStyle:NSRoundedBezelStyle];
//    [self.selectCustomerViewController prepareForDisplayWithSalon:self.salonDocument];
//    [self.selectItemsViewController prepareForDisplayWithSalon:self.salonDocument];
//    [self.makePaymentViewController prepareForDisplayWithSalon:self.salonDocument];
}

-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.currentStep = CreateSaleStepFirstStep;
    [self.editButton setHidden:YES];
    [self displayWizardStep];
    [self.doneButton setHidden:YES];
}
-(NSString *)objectTypeAndName {
    return @"Sale";
}
-(Sale *)sale {
    return (Sale*)self.objectToEdit;
}
- (IBAction)previousStep:(id)sender {
    if (self.currentStep == CreateSaleStepFirstStep) {
        return;
    }
    self.currentStep = self.currentStep - 1;
}
- (IBAction)nextStep:(id)sender {
    if (self.currentStep == CreateSaleStepLastStep) {
        return;
    }
    switch (self.currentStep) {
        case CreateSaleStepSelectCustomer:
        {
            break;
        }
        case CreateSaleStepSelectItems:
        {
            //
            break;
        }
        case CreateSaleStepMakePayment:
        {
            //
            break;
        }
    }
    self.currentStep = self.currentStep + 1;

}
-(CreateSaleStep)currentStep {
    return _currentStep;
}
-(void)setCurrentStep:(CreateSaleStep)step {
    if (step < CreateSaleStepFirstStep || step > CreateSaleStepLastStep) {
        return;
    }
    _currentStep = step;
    [self displayWizardStep];
    [self configureWizardButtons];
}
-(BOOL)customerSelected {
    return _customerSelected;
}
-(void)setCustomerSelected:(BOOL)customerSelected
{
    _customerSelected = customerSelected;
    Customer * newCustomer = [self.selectCustomerViewController objectForWizardStep];
    Customer * oldCustomer = self.sale.customer;
    if (oldCustomer != newCustomer && newCustomer) {
        self.sale.customer = [self.selectCustomerViewController objectForWizardStep];
        self.paymentMade = NO;
    }
    [self configureWizardButtons];
}
-(BOOL)itemsSelected {
    return _itemsSelected;
}
-(void)setItemsSelected:(BOOL)itemsSelected {
    _itemsSelected = itemsSelected;
    if (itemsSelected) {
        self.paymentMade = NO;
    } else {
    }
    [self configureWizardButtons];
}
-(BOOL)paymentMade {
    return _paymentMade;
}
-(void)setPaymentMade:(BOOL)paymentMade {
    _paymentMade = paymentMade;
    [self configureWizardButtons];
}
-(void)displayWizardStep
{
    if (self.viewToDisplay) {
        [self.viewToDisplay removeFromSuperview];
    }
    WizardStepViewController * wizardStepController = [self wizardStepController];
    [wizardStepController prepareForDisplayWithSalon:self.salonDocument];
    [self addWizardStepViewFromController:wizardStepController];
}
-(void)addWizardStepViewFromController:(WizardStepViewController*)viewController {
    while (self.wizardStepContainerView.subviews.count > 0) {
        NSView * view = self.wizardStepContainerView.subviews.firstObject;
        [view removeFromSuperview];
    }
    viewController.delegate = self;
    NSView * viewToDisplay = viewController.view;
    [viewController viewRevisited:nil];
    [viewToDisplay setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.wizardStepContainerView addSubview:viewToDisplay];
    NSDictionary * views = NSDictionaryOfVariableBindings(viewToDisplay);
    NSArray * constraints;
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[viewToDisplay]|" options:0 metrics:nil views:views];
    [self.wizardStepContainerView addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[viewToDisplay]|" options:0 metrics:nil views:views];
    [self.wizardStepContainerView addConstraints:constraints];
    [self.wizardStepContainerView setNeedsDisplay:YES];
    [self.viewToDisplay setNeedsDisplay:YES];
    [self configureWizardButtons];
    [viewController applyEditMode:self.editMode];
}
-(WizardStepViewController*)wizardStepController
{
    switch (self.currentStep) {
        case CreateSaleStepSelectCustomer:
        {
            return self.selectCustomerViewController;
        }
        case CreateSaleStepSelectItems:
        {
            return self.selectItemsViewController;
        }
        case CreateSaleStepMakePayment:
        {
            return self.makePaymentViewController;
        }
    }
}
-(void)configureWizardButtons {
    NSColor * greyBackground = [NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha:1];
    NSColor * blueBackground = [NSColor colorWithCalibratedRed:0.2 green:0.7 blue:1.0 alpha:1];
    [self.cancelButton setEnabled:YES];
    [self.doneButton setEnabled:self.paymentMade];
    [self.nextStep setEnabled:YES];
    [self.previousStep setEnabled:YES];
    [self.selectCustomerLabel setBackgroundColor:greyBackground];
    [self.chooseItemsLabel setBackgroundColor:greyBackground];
    [self.takePaymentLabel setBackgroundColor:greyBackground];
    [self.selectCustomerLabel setTextColor:[NSColor lightGrayColor]];
    [self.chooseItemsLabel setTextColor:[NSColor lightGrayColor]];
    [self.takePaymentLabel setTextColor:[NSColor lightGrayColor]];
    [self.takePaymentLabel setNeedsDisplay:YES];
    switch (self.currentStep) {
        case CreateSaleStepSelectCustomer:
        {
            [self.previousStep setEnabled:NO];
            if (self.customerSelected) {
                [self.nextStep setEnabled:YES];
                [self.nextStep.window setDefaultButtonCell:self.nextStep.cell];
            } else {
                [self.nextStep setEnabled:NO];
            }
            [self.selectCustomerLabel setBackgroundColor:blueBackground];
            [self.selectCustomerLabel setTextColor:[NSColor whiteColor]];
            break;
        }
        case CreateSaleStepSelectItems:
        {
            [self.previousStep setEnabled:YES];
            if (self.itemsSelected) {
                [self.nextStep setEnabled:YES];
                [self.nextStep.window setDefaultButtonCell:self.nextStep.cell];
            } else {
                [self.nextStep setEnabled:NO];
                [self.previousStep setEnabled:YES];
                [self.previousStep.window setDefaultButtonCell:self.previousStep.cell];
            }
            [self.chooseItemsLabel setBackgroundColor:blueBackground];
            [self.chooseItemsLabel setTextColor:[NSColor whiteColor]];
            break;
        }
        case CreateSaleStepMakePayment:
        {
            [self.previousStep setEnabled:YES];
            [self.nextStep setEnabled:NO];
            [self.takePaymentLabel setBackgroundColor:blueBackground];
            [self.takePaymentLabel setTextColor:[NSColor whiteColor]];
            if (self.paymentMade) {
                [self.doneButton.window setDefaultButtonCell:self.doneButton.cell];
            } else {
                [self.doneButton.window setDefaultButtonCell:nil];
            }
            break;
        }
    }
    [self.nextStep setNeedsDisplay:YES];
    [self.previousStep setNeedsDisplay:YES];
    [self.doneButton setNeedsDisplay:YES];
    [self.selectCustomerLabel setNeedsDisplay:YES];
    [self.chooseItemsLabel setNeedsDisplay:YES];
    [self.takePaymentLabel setNeedsDisplay:YES];
}
-(void)clear
{
    if (self.documentMoc) {
        [self.selectCustomerViewController clear];
        [self.selectItemsViewController clear];
        [self.makePaymentViewController clear];
    }
    if (self.editMode == EditModeCreate) {
        self.customerSelected = NO;
        self.itemsSelected = NO;
        self.paymentMade = NO;
    }
    _currentStep = CreateSaleStepSelectCustomer;
    [self.viewToDisplay removeFromSuperview];
    self.viewToDisplay = nil;
}

#pragma mark - AMCWizardStepDelegate
-(void)requestMoveToNextStep:(WizardStepViewController *)wizardStep {
    [self nextStep:wizardStep];
}
- (void)wizardStep:(id)wizardStep isValid:(BOOL)validity
{
    switch (self.currentStep) {
        case CreateSaleStepSelectCustomer:
        {
            self.customerSelected = validity;
            break;
        }
        case CreateSaleStepSelectItems:
        {
            self.itemsSelected = validity;
            break;
        }
        case CreateSaleStepMakePayment:
        {
            self.paymentMade = validity;
            if (validity) {
                [self doneButton:nil];
                MakePaymentStepViewController * vc = (MakePaymentStepViewController*)self.makePaymentViewController;
                if (vc.receiptRequired) {
                    // print receipt
                    self.receiptPrinterWindowController.sale = self.objectToEdit;
                    NSWindow * sheet = [self.receiptPrinterWindowController window];
                    NSWindow * window = [NSApp mainWindow];
                    [window beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
                        if (returnCode == NSModalResponseCancel) {
                            NSLog(@"User chose not to print the receipt after all");
                        } else {
                            NSLog(@"User chose to print the receipt");
                        }
                        vc.receiptRequired = NO;
                    }];
                }
            }
            break;
        }
    }
    [self configureWizardButtons];
}
-(Sale*)wizardStepRequiresSale:(WizardStepViewController *)wizardStep
{
    return (Sale*)self.objectToEdit;
}

@end
