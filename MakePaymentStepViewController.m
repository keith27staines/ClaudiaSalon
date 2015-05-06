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
#import "Service+Methods.h"
#import "Sale+Methods.h"
#import "SaleItem+Methods.h"
#import "AMCPaymentFormatter.h"
#import "AMCReceiptWindowController.h"
#import "AMCReceiptView.h"
#import "Account+Methods.h"
#import "AMCSalonDocument.h"
#import "Salon+Methods.h"

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
        [self.additionalDiscountPopup selectItemAtIndex:sale.discountType.integerValue];
        self.amountGivenByCustomer.delegate = self;
        self.amountGivenByCustomer.fontSize = 24;
        [self applySale];
        [self.paymentCompleteButton setBezelStyle:NSRoundedBezelStyle];
    }
    return view;
}

-(void)loadDiscountPopup
{
    [self.additionalDiscountPopup removeAllItems];
    for (int i = AMCDiscountMinimum; i<=AMCDiscountMaximum; i++) {
        NSString * discountDescription = [AMCDiscountCalculator discountDescriptionforDiscount:i];
        [self.additionalDiscountPopup insertItemWithTitle:discountDescription atIndex:i];
    }
    Sale * sale = [self sale];
    [self.additionalDiscountPopup selectItemAtIndex:sale.discountType.integerValue];
}
- (IBAction)extraDiscountChanged:(id)sender {
    Sale * sale = [self sale];
    sale.discountType = @(self.additionalDiscountPopup.indexOfSelectedItem);
    [self applySale];
}
-(void)clear
{
    [self.additionalDiscountPopup selectItemAtIndex:0];
    self.costOfAllWithoutAdditionalDiscount.stringValue = @"";
    self.totalDiscount.stringValue = @"";
    self.totalToPay.stringValue = @"";
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
        self.amountGivenByCustomer.doubleValue = sale.amountGivenByCustomer.doubleValue;
        [self.additionalDiscountPopup selectItemAtIndex:sale.discountType.integerValue];
        if (change >=0) {
            self.changeToReturn.stringValue = [NSString stringWithFormat:@"£%1.2f",change];
            
        } else {
            self.changeToReturn.stringValue = @"nil";
        }
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
-(AMCDiscount)extraDiscountType {
    AMCDiscount discountType = self.additionalDiscountPopup.indexOfSelectedItem;
    return discountType;
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
    Sale * sale = [self sale];
    [self.additionalDiscountPopup selectItemAtIndex:sale.discountType.integerValue];
    [self applySale];
}
- (IBAction)paymentComplete:(id)sender {
    [self.amountGivenByCustomer.window makeFirstResponder:nil];
    [self applySale];
    NSWindow * sheet = [self.paymentCompleteWindowController window];
    [NSApp beginSheet:sheet modalForWindow:self.view.window modalDelegate:self.view.window didEndSelector:NULL contextInfo:nil];
}

- (IBAction)saveAsQuote:(id)sender {
    Sale * sale = [self sale];
    [self applySale];
    sale.changeGiven = @(0);
    sale.isQuote = @(YES);
    sale.account = nil;
    [self.salonDocument commitAndSave:nil];
    [self.delegate wizardStep:self isValid:YES];
}
-(void)controlTextDidChange:(NSNotification *)obj
{
    Sale * sale = [self sale];
    [self.paymentCompleteButton setEnabled:NO];
    double d = self.amountGivenByCustomer.doubleValue;
    if (d >= sale.actualCharge.doubleValue) {
        [self.paymentCompleteButton setEnabled:YES];
        [self.paymentCompleteButton.window setDefaultButtonCell:self.paymentCompleteButton.cell];
    } else {
        [self.paymentCompleteButton setEnabled:NO];
    }
    sale.amountGivenByCustomer = @(d);
    [self applySale];
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
-(void)paymentCompleteController:(AMCPaymentCompleteWindowController *)controller didCompleteWithStatus:(BOOL)status
{
    if (status) {
        Sale * sale = [self sale];
        sale.amountGivenByCustomer = @(self.amountGivenByCustomer.doubleValue);
        sale.changeGiven = @([self calculateChange]);
        sale.isQuote = @(NO);
        [sale makePaymentInFull];
        sale.lastUpdatedDate = [NSDate date];
        [self.salonDocument commitAndSave:nil];
        if (controller.printReceiptCheckbox.state == NSOnState) {
            self.receiptRequired = YES;
        }
        [self.delegate wizardStep:self isValid:YES];
    }
}

- (IBAction)cardCashSegmentedControlChanged:(id)sender {
    if (self.cardCashSegmentedControl.selectedSegment == 0) {
        self.sale.account = self.salonDocument.salon.tillAccount;
    } else {
        self.sale.account = self.salonDocument.salon.cardPaymentAccount;
    }
    [self applySale];
}
@end
