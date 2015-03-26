//
//  AMCPaymentAmountViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 15/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCPaymentAmountViewController.h"
#import "Account+Methods.h"
#import "Payment+Methods.h"
#import "PaymentCategory+Methods.h"
#import "AMCConstants.h"

@interface AMCPaymentAmountViewController ()
{
    NSString * _title;
    NSString * _payee;
    NSString * _paymentReason;
    PaymentCategory * _paymentCategory;
    BOOL _allowingLowerPayment;
}

@property (nonatomic,copy) NSString * title;
@property (nonatomic,copy) NSString * payee;
@property (nonatomic,copy) NSString * paymentReason;
@property (nonatomic) PaymentCategory * paymentCategory;
@property (nonatomic) BOOL allowingLowerPayment;
@property (nonatomic) double amountToPay;
@property (nonatomic) Account * account;
@property (nonatomic) Payment * payment;

@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSPopUpButton *accountPopup;
@property (weak) IBOutlet NSTextField *amountTextField;
@property (weak) IBOutlet NSNumberFormatter *amountFormatter;
@property (weak) IBOutlet NSButton *payButton;

@end

@implementation AMCPaymentAmountViewController

- (IBAction)accountChanged:(id)sender {
    self.account = self.accountPopup.selectedItem.representedObject;
}

-(NSString *)nibName {
    return @"AMCPaymentAmountViewController";
}
-(void)makePaymentWithTitle:(NSString*)title
                     amount:(double)amount
       allowingLowerPayment:(BOOL)allowingLowerPayment
                 inCategory:(PaymentCategory*)category
                fromAccount:(Account*)account
                    toPayee:(NSString*)payee
                 withReason:(NSString*)reason {
    [self view];   // ensure loaded from nib so all actions and outlets connected
    self.titleLabel.stringValue = title;
    self.amountToPay = amount;
    self.allowingLowerPayment = allowingLowerPayment;
    self.paymentCategory = category;
    self.payee = payee;
    self.paymentReason = reason;
    self.account = account;
    self.payment = nil;
    [self populateAccounts];
}
-(void)populateAccounts {
    NSArray * accounts = [Account allObjectsWithMoc:self.documentMoc];
    [self.accountPopup removeAllItems];
    for (Account * account in accounts) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.title = account.friendlyName;
        menuItem.representedObject = account;
        [self.accountPopup.menu addItem:menuItem];
        if (account == self.account) {
            [self.accountPopup selectItem:menuItem];
        }
    }
}
- (IBAction)amountChanged:(id)sender {
    self.amountToPay = self.amountTextField.doubleValue;
}
- (IBAction)dismissController:(id)sender {
    if ([self.view.window makeFirstResponder:self.view.window] && self.amountToPay > 0) {
        self.payment = [Payment newObjectWithMoc:self.documentMoc];
        self.payment.reason = self.paymentReason;
        self.payment.paymentCategory = self.paymentCategory;
        self.payment.payeeName = self.payee;
        self.payment.direction = kAMCPaymentDirectionOut;
        self.payment.paymentDate = [NSDate date];
        self.payment.account = self.account;
        self.payment.amount = @(self.amountToPay);
        [super dismissController:self];
    }
}
-(void)setAmountToPay:(double)amountToPay {
    _amountToPay = amountToPay;
    self.amountTextField.doubleValue = amountToPay;
    self.amountFormatter.minimum = @0;
    self.payButton.enabled = (amountToPay > 0)?YES:NO;
}
-(void)setAllowingLowerPayment:(BOOL)allowingLowerPayment {
    _allowingLowerPayment = allowingLowerPayment;
    self.amountTextField.enabled = allowingLowerPayment;
}
-(Account*)account {
    if (!_account) {
        _account = [Account accountWithFriendlyName:kAMCBarclaysAccountName withMoc:self.documentMoc];
    }
    return _account;
}















@end
