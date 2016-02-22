//
//  AMCAdvancePayment.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 05/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCAdvancePayment.h"
#import "Appointment.h"
#import "Sale.h"
#import "Payment.h"
#import "Account.h"

@interface AMCAdvancePayment ()
@property (weak) IBOutlet NSTextField *amountTotalLabel;
@property (weak) IBOutlet NSPopUpButton *accountPopup;

@property (weak) IBOutlet NSTextField *amountAdvancedField;

@property (weak) IBOutlet NSButton *okButton;
@property (weak) IBOutlet NSButton *cancelButton;

@property (weak) IBOutlet NSPopUpButton *percentagePopup;
@property (readonly) Payment * advancePayment;
@property (readonly) Sale * sale;
@property (readonly) Account * account;
@end

@implementation AMCAdvancePayment

-(NSString *)nibName {
    return @"AMCAdvancePayment";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self loadAccountPopup];
    [self loadPercentagePopup];
    self.amountTotalLabel.objectValue = self.sale.actualCharge;
    if (self.advancePayment) {
        self.amountAdvancedField.objectValue = self.advancePayment.amount;
    } else {
        self.amountAdvancedField.objectValue = @(0);
    }
    [self enableEditableControls:![self isReadOnly]];
    self.okButton.enabled = NO;
}
-(void)loadAccountPopup {
    NSMenuItem * cardPaymentMenuItem;
    [self.accountPopup removeAllItems];
    for (Account * account in [Account allObjectsWithMoc:self.documentMoc]) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.title = account.friendlyName;
        menuItem.representedObject = account;
        [self.accountPopup.menu addItem:menuItem];
        if (account == self.advancePayment.account) {
            [self.accountPopup selectItem:menuItem];
        }
        if (account == self.salonDocument.salon.cardPaymentAccount) {
            cardPaymentMenuItem = menuItem;
        }
    }
    if (!self.advancePayment) {
        [self.accountPopup selectItem:cardPaymentMenuItem];
    }
}
-(void)loadPercentagePopup {
    [self.percentagePopup removeAllItems];
    [self.percentagePopup addItemWithTitle:@"Set amount from percentage"];
    for (int i = 0; i < 105; i = i + 5) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.title = [NSString stringWithFormat:@"%i percent",i];
        menuItem.representedObject = @(i/100.0);
        [self.percentagePopup.menu addItem:menuItem];
    }
}
-(void)enableEditableControls:(BOOL)enable {
    for (NSControl * control in [self editableControls]) {
        control.enabled = enable;
    }
}
-(void)enableOKButton {
    if ([self isValid]) {
        self.okButton.enabled = YES;
        [self.okButton.window setDefaultButtonCell:self.okButton.cell];
    } else {
        self.okButton.enabled = NO;
    }
    
}
- (IBAction)accountChanged:(id)sender {
    [self enableOKButton];
}
- (IBAction)percentageChanged:(id)sender {
    if (self.percentagePopup.selectedItem.representedObject) {
        NSNumber * percent = self.percentagePopup.selectedItem.representedObject;
        self.amountAdvancedField.doubleValue = percent.doubleValue * self.amountTotalLabel.doubleValue;
    }
    [self enableOKButton];
}
- (IBAction)amountAdvancedChanged:(id)sender {
    [self enableOKButton];
}
-(NSArray*)editableControls {
    return @[self.accountPopup, self.amountAdvancedField,self.percentagePopup];
}
-(BOOL)isReadOnly {
    if (!self.appointment || self.appointment.completed.boolValue) return YES;
    if (!self.sale || self.sale.voided.boolValue) return YES;
    if (self.advancePayment.isReconciled) return YES;
    return NO;
}
-(BOOL)isValid {
    if (self.amountAdvancedField.doubleValue < 1) return NO;
    if (!self.accountPopup.selectedItem.representedObject) return NO;
    return YES;
}
-(Account *)account {
    return self.advancePayment.account;
}
-(Sale *)sale {
    return self.appointment.sale;
}
-(Payment*)advancePayment {
    return self.sale.advancePayment;
}
-(void)dismissController:(id)sender {
    if (![self.view.window makeFirstResponder:nil]) {
        [self.view.window endEditingFor:nil];
    }
    if (sender == self.okButton && ![self isReadOnly]) {
        if ([self isValid]) {
            [self.sale makeAdvancePayment:self.amountAdvancedField.doubleValue inAccount:self.accountPopup.selectedItem.representedObject];
        } else {
            double amount = self.amountAdvancedField.doubleValue;
            if (amount < 1) {
                NSAlert * alert = [[NSAlert alloc] init];
                alert.messageText = @"The amount being advanced is too small";
                alert.informativeText = @"Increase the amount being advanced";
                [alert runModal];
                return;
            }
            if (!self.accountPopup.selectedItem.representedObject) {
                NSAlert * alert = [[NSAlert alloc] init];
                alert.messageText = @"An account is required in order to take advance payment";
                alert.informativeText = @"Please select an account";
                [alert runModal];
                return;
            }
        }
    }
    [super dismissController:sender];
}
@end
