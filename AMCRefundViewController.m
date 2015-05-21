//
//  AMCRefundViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 09/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCRefundViewController.h"
#import "Account+Methods.h"
#import "Sale+Methods.h"
#import "SaleItem+Methods.h"
#import "Customer+Methods.h"
#import "Payment+Methods.h"
#import "Service+Methods.h"
#import "AMCSalonDocument.h"

@interface AMCRefundViewController ()
{
    __weak SaleItem * _saleItem;
}
@end

@implementation AMCRefundViewController
-(NSString *)nibName
{
    return @"AMCRefundViewController";
}
-(void)viewDidAppear
{
    self.saleItem = self.saleItem;
}
- (IBAction)cancelButton:(id)sender {
    [self.presentingViewController dismissViewController:self];
}

- (IBAction)refundButtonClicked:(id)sender {
    Account * account = self.saleItem.sale.account;
    Payment * payment = [account makePaymentWithAmount:@(self.actualSumToRefund.doubleValue)
                                                  date:[NSDate date]
                                              category:nil
                                             direction:kAMCPaymentDirectionOut
                                             payeeName:self.saleItem.sale.customer.fullName
                                                reason:self.refundReason.stringValue];
    payment.refunding = self.saleItem;
    [self.presentingViewController dismissViewController:self];
}

-(void)setSaleItem:(SaleItem *)saleItem
{
    _saleItem = saleItem;
    self.saleitemToRefundLabel.stringValue = saleItem.service.name;
    double amountPaid = [self amountPaidAfterDiscount];
    self.amountPaidLabel.stringValue = [NSString stringWithFormat:@"£%1.2f",amountPaid];
    self.actualSumToRefund.doubleValue = amountPaid;
    [self.amountToRefundFormatter setMinimum:@(0)];
    [self.amountToRefundFormatter setMaximum:@(amountPaid)];
    if (saleItem.refund) {
        // Refund already exists - just allow the user to view it
        [self.actualSumToRefund setEnabled:YES];
        [self.actualSumToRefund setEditable:NO];
        [self.refundReason setEnabled:YES];
        [self.refundReason setEditable:NO];
        self.refundReason.stringValue = saleItem.refund.reason;
        [self.repayButton setHidden:YES];
        self.titleField.stringValue = @"The customer was refunded for this item";
        self.sumToRefundField.stringValue = @"Amount refunded";
    } else {
        // Allow the user to create a refund
        [self.actualSumToRefund setEnabled:YES];
        [self.actualSumToRefund setEditable:YES];
        [self.refundReason setEnabled:YES];
        [self.refundReason setEditable:YES];
        self.refundReason.stringValue = @"";
        [self.repayButton setHidden:NO];
        self.titleField.stringValue = @"Refund the customer for this item?";
        self.sumToRefundField.stringValue = @"Enter amount to refund";
    }
    [self.repayButton setEnabled:NO];
}
-(double)amountPaidAfterDiscount
{
    double amountPaid;
    if (self.saleItem.actualCharge == self.saleItem.nominalCharge) {
        Sale * sale = self.saleItem.sale;
        if (sale.actualCharge == sale.nominalCharge) {
            amountPaid = self.saleItem.actualCharge.doubleValue;
        } else {
            double p = self.saleItem.actualCharge.doubleValue / self.saleItem.nominalCharge.doubleValue;
            amountPaid = p * self.saleItem.nominalCharge.doubleValue;
        }
    } else {
        amountPaid = self.saleItem.actualCharge.doubleValue;
    }
    return floor(amountPaid * 100.0)/100.0;
}
-(SaleItem *)saleItem
{
    return _saleItem;
}
-(void)controlTextDidBeginEditing:(NSNotification *)obj
{
    [self.repayButton setEnabled:NO];
}
-(void)controlTextDidChange:(NSNotification *)obj
{
    if (!self.saleItem.refund
        && self.refundReason.stringValue.length > 0
        && self.actualSumToRefund.doubleValue > 0
        && self.actualSumToRefund.doubleValue <= self.saleItem.actualCharge.doubleValue) {
        [self.repayButton setEnabled:YES];
    } else {
        [self.repayButton setEnabled:NO];
    }
}
@end
