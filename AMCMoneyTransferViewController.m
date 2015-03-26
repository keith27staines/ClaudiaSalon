//
//  AMCMoneyTransferViewController.m
//  ClaudiasSalon
//
//  Created by service on 28/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCMoneyTransferViewController.h"
#import "AMCConstants.h"
#import "Account+Methods.h"
#import "Payment+Methods.h"
#import "AMCSalonDocument.h"
#import "PaymentCategory+Methods.h"

@interface AMCMoneyTransferViewController ()
{

}
@property NSArray * accounts;
@property (readonly) Account * inAccount;
@property (readonly) Account * outAccount;
@end

@implementation AMCMoneyTransferViewController

-(NSString *)nibName {
    return @"AMCMoneyTransferViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self loadAccountPopupButton:self.fromAccountPopupButton];
    [self loadAccountPopupButton:self.toAccountPopupButton];
    [self reloadData];
}
-(void)reloadData {
    Account * till = [Account accountWithFriendlyName:kAMCTillAccountName withMoc:self.documentMoc];
    Account * barclays = [Account accountWithFriendlyName:kAMCBarclaysAccountName withMoc:self.documentMoc];
    [self.fromAccountPopupButton selectItemAtIndex:[self.accounts indexOfObject:till]];
    [self.toAccountPopupButton selectItemAtIndex:[self.accounts indexOfObject:barclays]];
    [self enableOKButton];
}
-(void)loadAccountPopupButton:(NSPopUpButton*)popup {
    [popup removeAllItems];
    self.accounts = [Account allObjectsWithMoc:self.documentMoc];
    for (Account * account in self.accounts) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.title = account.friendlyName;
        menuItem.representedObject = account;
        [popup.menu addItem:menuItem];
    }
}
- (IBAction)fromAccountChanged:(NSPopUpButton *)sender {
    [self enableOKButton];
}

- (IBAction)toAccountChanged:(id)sender {
    [self enableOKButton];
}
-(void)enableOKButton {
    if (self.inAccount == self.outAccount) {
        [self.okButton setEnabled:NO];
    } else {
        [self.okButton setEnabled:YES];
    }
    if (self.amountToTransfer.doubleValue <= 0) {
        [self.okButton setEnabled:NO];
    }
}
-(Account*)outAccount {
    return self.fromAccountPopupButton.selectedItem.representedObject;
}
-(Account*)inAccount {
    return self.toAccountPopupButton.selectedItem.representedObject;
}
- (IBAction)okButonClicked:(id)sender {
    if (![self.view.window makeFirstResponder:self.view.window]) {
        return;
    }
    Payment * outPayment = [Payment newObjectWithMoc:self.documentMoc];
    Payment * inPayment = [Payment newObjectWithMoc:self.documentMoc];
    PaymentCategory * transferCategory = [PaymentCategory transferCategoryWithMoc:self.documentMoc];
    outPayment.paymentCategory = transferCategory;
    inPayment.paymentCategory = transferCategory;
    outPayment.account = self.fromAccountPopupButton.selectedItem.representedObject;
    inPayment.account = self.toAccountPopupButton.selectedItem.representedObject;
    outPayment.direction = kAMCPaymentDirectionOut;
    inPayment.direction = kAMCPaymentDirectionIn;
    outPayment.amount = @(self.amountToTransfer.doubleValue);
    inPayment.amount = @(self.amountToTransfer.doubleValue);
    outPayment.reason = [NSString stringWithFormat:@"Transfer to %@",self.inAccount.friendlyName];
    inPayment.reason = [NSString stringWithFormat:@"Transfer from %@",self.outAccount.friendlyName];
    NSDate * date = [NSDate date];
    outPayment.paymentDate = date;
    inPayment.paymentDate = [date dateByAddingTimeInterval:1]; // 1 second later!
    outPayment.payeeName = [self.inAccount.friendlyName stringByAppendingString:@" acct"];
    inPayment.payeeName = [self.outAccount.friendlyName stringByAppendingString:@" acct"];
    [self.salonDocument commitAndSave:nil];
    [self dismissController:self];
}
- (IBAction)cancelButtonClicked:(id)sender {
    [self dismissController:self];
}
-(void)controlTextDidChange:(NSNotification *)obj {
    [self enableOKButton];
}
@end
