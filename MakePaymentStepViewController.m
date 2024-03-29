//
//  MakePaymentStepViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 27/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "MakePaymentStepViewController.h"
#import "AMCConstants.h"
#import "AMCDiscountCalculator.h"
#import "Service.h"
#import "Sale.h"
#import "SaleItem.h"
#import "AMCPaymentFormatter.h"
#import "AMCReceiptWindowController.h"
#import "AMCReceiptView.h"
#import "Account.h"
#import "AMCSalonDocument.h"
#import "Salon.h"
#import "Payment.h"

@interface MakePaymentStepViewController ()
{

}

@end

@implementation MakePaymentStepViewController

-(NSString *)nibName
{
    return @"MakePaymentStepViewController";
}
-(NSView *)view
{
    static BOOL loaded = NO;
    NSView * view = [super view];
    if (!loaded) {
        loaded = YES;
        [self loadDiscountPopup];
        Sale * sale = [self sale];
        [self.additionalDiscountPopup selectItemAtIndex:sale.discountValue.integerValue];
        self.discountTypeSegmentedControl.selectedSegment = (sale.discountType.integerValue==AMCDiscountTypePercentage)?0:1;
        self.amountGivenByCustomer.delegate = self;
        self.amountGivenByCustomer.fontSize = 24;
        [self applySale];
        [self.paymentCompleteButton setBezelStyle:NSRoundedBezelStyle];
    }
    return view;
}
-(void)viewDidAppear {
    self.amountGivenByCustomer.fontSize = 24;
    [self.amountGivenByCustomer setNeedsLayout:YES];
}

-(void)loadDiscountPopup
{
    [self.additionalDiscountPopup removeAllItems];
    NSString * currencySymbol = @"£";
    NSString * percentSymbol = @"%";
    NSString * discountString = @"";
    Sale * sale = [self sale];
    self.discountTypeSegmentedControl.selectedSegment = (sale.discountType.integerValue==AMCDiscountTypePercentage)?0:1;
    for (int i = 0; i <= 100; i++) {
        if (sale.discountType.integerValue == AMCDiscountTypePercentage) {
            // Percent
            discountString = [NSString stringWithFormat:@"%@ %@",@(i),percentSymbol];
        } else {
            // Absolute amount
            discountString = [NSString stringWithFormat:@"%@ %@",currencySymbol,@(i)];
        }
        [self.additionalDiscountPopup insertItemWithTitle:discountString atIndex:i];
    }
    [self.additionalDiscountPopup selectItemAtIndex:sale.discountValue.integerValue];
}
- (IBAction)extraDiscountChanged:(id)sender {
    Sale * sale = [self sale];
    sale.discountType = @((self.discountTypeSegmentedControl.selectedSegment==0)?AMCDiscountTypePercentage:AMCDiscountTypeAbsoluteAmount);
    sale.discountValue = @(self.additionalDiscountPopup.indexOfSelectedItem);
    [self applySale];
    sale.bqNeedsCoreDataExport =@YES;
}
- (IBAction)discountTypeChanged:(id)sender {
    Sale * sale = [self sale];
    sale.discountType = @((self.discountTypeSegmentedControl.selectedSegment==0)?AMCDiscountTypePercentage:AMCDiscountTypeAbsoluteAmount);
    [self loadDiscountPopup];
    [self applySale];
    sale.bqNeedsCoreDataExport =@YES;
}
-(void)clear
{
    [self.additionalDiscountPopup selectItemAtIndex:0];
    self.costOfAllWithoutAdditionalDiscount.stringValue = @"";
    self.totalDiscount.stringValue = @"";
    self.discountTypeSegmentedControl.selectedSegment = 1;
    self.totalToPay.stringValue = @"";
    self.alreadyPaid.doubleValue = 0;
    self.amountGivenByCustomer.doubleValue = 0;
    self.changeToReturn.stringValue = @"";
    [self.view.window makeFirstResponder:self.amountGivenByCustomer];
    [self.delegate wizardStep:self isValid:NO];
    [self.paymentCompleteButton setEnabled:NO];
    [self.delegate wizardStep:self isValid:NO];
    [self.cardCashSegmentedControl selectSegmentWithTag:0];
}
-(void)applyEditMode:(EditMode)editMode {
    [super applyEditMode:editMode];
}
-(void)applySale
{
    double undiscountedCharge;
    double chargeAfterIndividualDiscounts;
    double totalDiscount;
    double totalToPay;
    double change;
    self.receiptRequired = NO;
    Sale * sale = [self sale];
    if (sale) {
        if (!sale.account) {
            sale.account = self.salonDocument.salon.tillAccount;
        }
        if (self.editMode == EditModeCreate || self.editMode == EditModeEdit) {
            if (sale.account == self.salonDocument.salon.tillAccount) {
                [self.cardCashSegmentedControl selectSegmentWithTag:0];
            } else {
                [self.cardCashSegmentedControl selectSegmentWithTag:1];
            }
            [sale updatePriceFromSaleItems];
            change = [self calculateChange];
        } else {
            change = sale.changeGiven.doubleValue;
        }
        undiscountedCharge = sale.nominalCharge.doubleValue;
        chargeAfterIndividualDiscounts = sale.chargeAfterIndividualDiscounts.doubleValue;
        totalDiscount = sale.discountAmount.doubleValue;
        totalToPay = sale.amountOutstanding;
        self.costOfAllWithoutAdditionalDiscount.stringValue = [NSString stringWithFormat:@"£%1.2f",undiscountedCharge];
        self.costAfterIndividualDiscounts.stringValue = [NSString stringWithFormat:@"£%1.2f",chargeAfterIndividualDiscounts];
        self.totalDiscount.stringValue = [NSString stringWithFormat:@"£%1.2f",totalDiscount];
        self.totalToPay.stringValue = [NSString stringWithFormat:@"£%1.2f",totalToPay];
        self.alreadyPaid.doubleValue = sale.amountAdvanced;
        self.amountGivenByCustomer.doubleValue = sale.amountGivenByCustomer.doubleValue;
        [self.additionalDiscountPopup selectItemAtIndex:sale.discountValue.integerValue];
        self.discountTypeSegmentedControl.selectedSegment = (sale.discountType.integerValue == AMCDiscountTypePercentage)?0:1;
        if (change >=0) {
            self.changeToReturn.stringValue = [NSString stringWithFormat:@"£%1.2f",change];
            
        } else {
            self.changeToReturn.stringValue = @"nil";
        }
        [self configurePaymentCompleteButton];
    }
}
-(double)roundUpPenny:(double)amount
{
    return ceil(amount * 100.0) / 100.0;
}
-(double)roundDownPenny:(double)amount
{
    return floor(amount * 100.0) / 100.0;
}
-(double)calculateChange
{
    Sale * sale = [self sale];
    double amountGiven = self.amountGivenByCustomer.doubleValue;
    return amountGiven - sale.amountOutstanding;
}
-(Sale*)sale
{
    Sale * sale = [self.delegate wizardStepRequiresSale:self];
    if (!sale.account) {
        sale.account = self.salonDocument.salon.tillAccount;
    }
    return sale;
}
-(void)viewRevisited:(NSView *)view
{
//    Sale * sale = [self sale];
//    [self.additionalDiscountPopup selectItemAtIndex:sale.discountValue.integerValue];
    [self applySale];
}
- (IBAction)paymentComplete:(id)sender {
    [self.amountGivenByCustomer.window makeFirstResponder:nil];
    [self applySale];
    NSWindow * sheet = [self.paymentCompleteWindowController window];
    NSWindow * window = self.view.window;
    [window beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseCancel) {
            NSLog(@"The user cancelled and no payment was made");
        } else {
            NSLog(@"The user accepted the payment from the customer");
            Sale * sale = [self sale];
            sale.amountGivenByCustomer = @(self.amountGivenByCustomer.doubleValue);
            sale.changeGiven = @([self calculateChange]);
            sale.isQuote = @(NO);
            [sale makePaymentInFull];
            sale.lastUpdatedDate = [NSDate date];
            if (self.paymentCompleteWindowController.printReceiptCheckbox.state == NSOnState) {
                self.receiptRequired = YES;
            }
            [self.delegate wizardStep:self isValid:YES];
        }
    }];
}

- (IBAction)saveAsQuote:(id)sender {
    Sale * sale = [self sale];
    [self applySale];
    sale.changeGiven = @(0);
    sale.isQuote = @(YES);
    sale.account = nil;
    [self.delegate wizardStep:self isValid:YES];
}
-(void)controlTextDidChange:(NSNotification *)obj
{
    Sale * sale = [self sale];
    [self configurePaymentCompleteButton];
    double d = self.amountGivenByCustomer.doubleValue;
    sale.amountGivenByCustomer = @(d);
    [self applySale];
}
-(void)configurePaymentCompleteButton {
    Sale * sale = [self sale];
    [self.paymentCompleteButton setEnabled:NO];
    double d = self.amountGivenByCustomer.doubleValue;
    if (d >= sale.amountOutstanding) {
        [self.paymentCompleteButton setEnabled:YES];
        [self.paymentCompleteButton.window setDefaultButtonCell:self.paymentCompleteButton.cell];
    } else {
        [self.paymentCompleteButton setEnabled:NO];
    }
}
-(void)cashEntryDidBeginEditing:(AMCCashEntryField *)cashEntryField {

}
-(void)cashEntryDidChange:(AMCCashEntryField *)cashEntryField {
    Sale * sale = [self sale];
    [self.paymentCompleteButton setEnabled:NO];
    double d = self.amountGivenByCustomer.doubleValue;
    
    if (round(d*100.0) >= round(sale.amountOutstanding*100.0)) {
        [self.paymentCompleteButton setEnabled:YES];
        [self.paymentCompleteButton.window setDefaultButtonCell:self.paymentCompleteButton.cell];
    } else {
        [self.paymentCompleteButton setEnabled:NO];
    }
    sale.amountGivenByCustomer = @(d);
    [self applySale];
}
-(void)cashEntryDidEndEditing:(AMCCashEntryField *)cashEntryField {
    [self cashEntryDidChange:cashEntryField];
}
-(void)controlTextDidBeginEditing:(NSNotification *)obj
{

}
-(void)controlTextDidEndEditing:(NSNotification *)obj
{
    [self applySale];
}
- (IBAction)amountGivenByCustomerFieldChanged:(id)sender
{
    Sale * sale = [self sale];
    sale.amountGivenByCustomer = @(self.amountGivenByCustomer.doubleValue);
    [self applySale];
}
#pragma mark - AMCPaymentCompleteWindowControllerDelegate
- (IBAction)cardCashSegmentedControlChanged:(id)sender {
    if (self.cardCashSegmentedControl.selectedSegment == 0) {
        self.sale.account = self.salonDocument.salon.tillAccount;
    } else {
        self.sale.account = self.salonDocument.salon.cardPaymentAccount;
    }
    [self applySale];
}

@end
