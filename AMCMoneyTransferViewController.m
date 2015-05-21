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
#import "Salon+Methods.h"
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
    [self.fromAccountPopupButton selectItemAtIndex:[self.accounts indexOfObject:self.salonDocument.salon.tillAccount]];
    [self.toAccountPopupButton selectItemAtIndex:[self.accounts indexOfObject:self.salonDocument.salon.primaryBankAccount]];
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
    if (![self.view.window makeFirstResponder:self.view.window]) {return;}

    NSDate * date = [NSDate date];
    PaymentCategory * transferCategory = self.salonDocument.salon.defaultPaymentCategoryForMoneyTransfers; //[PaymentCategory transferCategoryWithMoc:self.documentMoc];
    // Create outgoing payment datestamped "now"
    [self.outAccount makePaymentWithAmount:@(self.amountToTransfer.doubleValue)
                                      date:date
                                  category:transferCategory
                                 direction:kAMCPaymentDirectionOut
                                 payeeName:[self.inAccount.friendlyName stringByAppendingString:@" account"]
                                    reason:[NSString stringWithFormat:@"Transfer to %@",self.inAccount.friendlyName]];
    // Create incoming payment datestamped 1 second later
    [self.inAccount makePaymentWithAmount:@(self.amountToTransfer.doubleValue)
                                     date:[date dateByAddingTimeInterval:1]
                                 category:transferCategory
                                direction:kAMCPaymentDirectionIn
                                payeeName:[self.outAccount.friendlyName stringByAppendingString:@" account"]
                                   reason:[NSString stringWithFormat:@"Transfer from %@",self.outAccount.friendlyName]];
    
    [self dismissController:self];
}
- (IBAction)cancelButtonClicked:(id)sender {
    [self dismissController:self];
}
-(void)controlTextDidChange:(NSNotification *)obj {
    [self enableOKButton];
}
@end
