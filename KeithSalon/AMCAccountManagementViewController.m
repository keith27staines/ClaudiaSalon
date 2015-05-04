//
//  AMCAccountManagementViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCAccountManagementViewController.h"
#import "AMCSalonDocument.h"
#import "Salon+Methods.h"
#import "Account+Methods.h"

@interface AMCAccountManagementViewController () <NSTableViewDelegate>
@property (strong) IBOutlet NSArrayController *accountArrayController;
@property (weak) IBOutlet NSTableView *accountsTable;
@property (weak) IBOutlet NSTextField *feePercentageIncomingField;
@property (weak) IBOutlet NSTextField *feePercentageOutgoingField;

@property (weak) IBOutlet NSButton *isPrimaryAccountCheckbox;
@property (weak) IBOutlet NSButton *isTillAccountCheckbox;
@property (weak) IBOutlet NSButton *isCardPaymentAccountCheckbox;
@end

@implementation AMCAccountManagementViewController

-(NSString *)nibName {
    return @"AMCAccountManagementViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.accountsTable.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"friendlyName" ascending:YES]];
}

- (IBAction)addAccount:(id)sender {
    Account * account = [Account newObjectWithMoc:self.documentMoc];
    account.friendlyName = @"New account";
    [self.accountArrayController addObject:account];
}

- (IBAction)removeAccount:(id)sender {
    NSArray * accounts = self.accountArrayController.selectedObjects;
    if (accounts.count > 0) {
        Account * account = accounts[0];
        if (account.payments.count > 0 || account.sales.count > 0) {
            NSAlert * alert = [[NSAlert alloc] init];
            alert.messageText = @"Account cannot be deleted";
            alert.informativeText = @"This account has at least one sale or payment recorded against it";
            [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                
            }];
        } else {
            [self.accountArrayController remove:self];
        }
    }
}

-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView * table = notification.object;
    NSInteger row = table.selectedRow;
    self.feePercentageIncomingField.enabled = NO;
    self.feePercentageOutgoingField.enabled = NO;
    self.feePercentageIncomingField.doubleValue = 0;
    self.feePercentageOutgoingField.doubleValue = 0;
    self.isCardPaymentAccountCheckbox.state = NSOffState;
    self.isPrimaryAccountCheckbox.state = NSOffState;
    self.isCardPaymentAccountCheckbox.enabled = NO;
    self.isTillAccountCheckbox.enabled = NO;
    self.isPrimaryAccountCheckbox.enabled = NO;
    self.isTillAccountCheckbox.state = NSOffState;
    if (row >= 0) {
        // A row is selected
        self.feePercentageIncomingField.enabled = YES;
        self.feePercentageOutgoingField.enabled = YES;
        self.isCardPaymentAccountCheckbox.enabled = YES;
        self.isTillAccountCheckbox.enabled = YES;
        self.isPrimaryAccountCheckbox.enabled = YES;
        Account * account = self.accountArrayController.arrangedObjects[row];
        self.feePercentageIncomingField.objectValue = account.transactionFeePercentageIncoming;
        self.feePercentageOutgoingField.objectValue = account.transactionFeePercentageOutgoing;
        if (account.primaryBankAccountForSalon) {
            self.isPrimaryAccountCheckbox.state = NSOnState;
        }
        if (account.tillAccountForSalon) {
            self.isTillAccountCheckbox.state = NSOnState;
        }
        if (account.cardPaymentAccountForSalon) {
            self.isCardPaymentAccountCheckbox.state = NSOnState;
        }
    }
}
- (IBAction)doneButtonClicked:(id)sender {
    NSString * missingAccounts = @"";
    if (!self.salonDocument.salon.primaryBankAccount) {
        missingAccounts = [missingAccounts stringByAppendingFormat:@"\nPrimary bank account has not been set."];
    }
    if (!self.salonDocument.salon.cardPaymentAccount) {
        missingAccounts = [missingAccounts stringByAppendingFormat:@"\nCard payment account has not been set. You will not be able to record card sales."];
    }
    if (!self.salonDocument.salon.tillAccount) {
        missingAccounts = [missingAccounts stringByAppendingFormat:@"\nTill account has not been set. You will not be able to record cash sales"];
    }
    if (missingAccounts.length > 0) {
        NSAlert * alert = [[NSAlert alloc] init];
        alert.messageText = @"Accounts are not fully configured";
        alert.informativeText = missingAccounts;
        [alert addButtonWithTitle:@"Configure accounts now"];
        [alert addButtonWithTitle:@"Leave until later"];
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertSecondButtonReturn) {
                [self dismissController:self];
            }
        }];
    } else {
        [self dismissController:self];
    }
}
- (IBAction)primaryBankAccountChanged:(id)sender {
    Salon * salon = (self.isPrimaryAccountCheckbox.state)?self.salonDocument.salon:nil;
    [self selectedAccount].primaryBankAccountForSalon = salon;
}
- (IBAction)tillAccountChanged:(id)sender {
    Salon * salon = (self.isTillAccountCheckbox.state)?self.salonDocument.salon:nil;
    [self selectedAccount].tillAccountForSalon = salon;
}
- (IBAction)cardpaymentAccountChanged:(id)sender {
    Salon * salon = (self.isCardPaymentAccountCheckbox.state)?self.salonDocument.salon:nil;
    [self selectedAccount].cardPaymentAccountForSalon = salon;
}
- (IBAction)feeIncomingChanged:(id)sender {
    [self selectedAccount].transactionFeePercentageIncoming = self.feePercentageIncomingField.objectValue;
}
- (IBAction)feeOutgoingChanged:(id)sender {
    [self selectedAccount].transactionFeePercentageOutgoing = self.feePercentageOutgoingField.objectValue;
}

-(Account*)selectedAccount {
    Account * account = self.accountArrayController.selectedObjects[0];
    return account;
}
@end
