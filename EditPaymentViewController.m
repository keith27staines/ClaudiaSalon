//
//  EditPaymentWindowController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 08/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditPaymentViewController.h"
#import "Payment+Methods.h"
#import "PaymentCategory+Methods.h"
#import "Account+Methods.h"
#import "AMCSalonDocument.h"
@interface EditPaymentViewController ()
{
    NSArray * _categories;
}
@property (weak,readonly) Payment * payment;
@property NSArray * accounts;
@property (readonly) NSArray * categories;
@property (weak) PaymentCategory * defaultCategory;
@end

@implementation EditPaymentViewController
-(BOOL)selectCategoryInPopup:(PaymentCategory*)category {
    for (NSMenuItem * item in self.categoryPopup.menu.itemArray) {
        if (item.representedObject == category) {
            [self.categoryPopup selectItem:item];
            return YES;
        }
    }
    return NO;
}
-(NSArray*)categories {
    if (!_categories) {
        _categories = [PaymentCategory allObjectsWithMoc:self.documentMoc];
    }
    return _categories;
}
-(void)populatePaymentCategoryPopup {
    [self.categoryPopup removeAllItems];
    NSMenuItem * menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"- Select category -";
    [self.categoryPopup.menu addItem:menuItem];
    [self.categoryPopup selectItem:menuItem];
    menuItem = [NSMenuItem separatorItem];
    [self.categoryPopup.menu addItem:menuItem];
    for (PaymentCategory * category in self.categories) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.title = category.categoryName;
        menuItem.representedObject = category;
        if (category.isDefault.boolValue) {
            [self.categoryPopup.menu insertItem:menuItem atIndex:1];
            self.defaultCategory = category;
        } else {
            [self.categoryPopup.menu addItem:menuItem];
        }
    }
}
-(NSString *)nibName
{
    return @"EditPaymentViewController";
}
-(NSString *)objectTypeAndName
{
    NSMutableString * objectTypeAndName = [@"Payment" mutableCopy];
    if (self.objectToEdit) {
        NSString * objectName = @"";
        if (objectName) {
            [objectTypeAndName appendString:@": "];
            [objectTypeAndName appendString:objectName];
        }
    }
    return objectTypeAndName;
}
-(void)clear
{
    self.paymentReasonField.stringValue = @"";
    self.payeeField.stringValue = @"";
    [self.paymentDatePicker setDateValue:[NSDate date]];
    self.amountField.stringValue = @"";
    self.feeField.stringValue = @"";
    [self.isRefundCheckbox setState:NSOffState];
    [self.categoryPopup selectItemAtIndex:0];
}
-(void)setObjectToEdit:(id)objectToEdit {
    [super setObjectToEdit:objectToEdit];
}
-(void)editObject {
    // Can only edit payments, not sales or anything else
    if (![self.objectToEdit isKindOfClass:[Payment class]]) {
        return;
    }
    Payment * payment = self.payment;
    self.paymentReasonField.stringValue = (payment.reason)?payment.reason:@"";
    self.payeeField.stringValue = (payment.payeeName)?payment.payeeName:@"";
    self.amountField.doubleValue = (payment.amount)?payment.amount.doubleValue:0;
    self.feeField.objectValue = payment.transactionFee;
    [self selectCategoryInPopup:payment.paymentCategory];
    if (payment.paymentDate) {
        self.paymentDatePicker.dateValue = payment.paymentDate;
    } else {
        self.paymentDatePicker.dateValue = [NSDate date];
    }
    self.isRefundCheckbox.state = (payment.refunding)?NSOnState:NSOffState;
    if (payment.isIncoming) {
        [self.paymentDirection selectSegmentWithTag:1];
    } else {
        [self.paymentDirection selectSegmentWithTag:0];
    }
    [self configureBankStatementReconciliationWithPayment];
}
-(void)enterEditMode:(NSButton *)sender {
    if (self.payment.isReconciled) {
        NSAlert * alert = [[NSAlert alloc] init];
        alert.messageText = @"Payment cannot be edited or voided";
        alert.informativeText = @"The date of the last account reconciliation point for the payment's account is later than the payment date. The details of this payment are now fixed in order to protect the validity of the accounts";
        [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
            
        }];
    } else {
        [super enterEditMode:sender];
    }
}
-(void)loadAccountsPopup {
    [self.accountPopupButton removeAllItems];
    self.accounts = [Account allObjectsWithMoc:self.documentMoc];
    for (Account * account in self.accounts) {
        NSMenuItem * menuItem = [[NSMenuItem alloc] init];
        menuItem.title = account.friendlyName;
        menuItem.representedObject = account;
        [self.accountPopupButton.menu addItem:menuItem];
        if (account == self.payment.account) {
            [self.accountPopupButton selectItem:menuItem];
        }
    }
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument
{
    [self setObjectToEdit:self.objectToEdit];
    [super prepareForDisplayWithSalon:salonDocument];
    [self clear];
    [self loadAccountsPopup];
    [self populatePaymentCategoryPopup];
    [self.isRefundCheckbox setEnabled:NO];  // read only
    [self.reconciledWithBankStatementCheckbox setEnabled:NO];
    [self editObject];
}
-(Payment*)payment
{
    return (Payment*)self.objectToEdit;
}
-(NSArray *)editableControls
{
    return  @[self.paymentReasonField,
              self.payeeField,
              self.amountField,
              self.feeField,
              self.paymentDirection,
              self.paymentDatePicker,
              self.categoryPopup,
              self.accountPopupButton];
}
#pragma mark - NSControlTextEditingDelegate
-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    BOOL controlIsValid = NO;
    [self.doneButton setEnabled:NO];
    
    if (control == self.amountField) {
        controlIsValid = self.amountField.doubleValue > 0;
    }
    if (control == self.feeField) {
        controlIsValid = self.feeField.doubleValue >= 0;
    }
    if (control == self.payeeField) {
        controlIsValid = [self validateName:fieldEditor.string];
    }
    if (control == self.paymentReasonField) {
        controlIsValid = [self validateName:fieldEditor.string];
    }
    [self.doneButton setEnabled:[self isValid]];
    return controlIsValid;
}
-(void)autoUpdateFee {
    double amount = self.amountField.doubleValue;
    Account * account = self.accountPopupButton.selectedItem.representedObject;
    if (account) {
        if (self.paymentDirection.selectedSegment == 0) {
            self.feeField.doubleValue = 0;
        } else {
            self.feeField.doubleValue = round(account.transactionFeePercentageIncoming.doubleValue * amount*100.0)/100.0;
        }
    }
}
-(void)controlTextDidEndEditing:(NSNotification *)obj
{
    if (obj.object == self.amountField && self.editMode == EditModeCreate) {
        [self autoUpdateFee];
    }
    [self.doneButton setEnabled:[self isValid]];
}
-(BOOL)isValid
{
    if (!self.categoryPopup.selectedItem.representedObject) return NO;
    if (self.amountField.doubleValue < 0.009999999) return NO;
    if (![self validateName:self.payeeField.stringValue]) return NO;
    if (![self validateName:self.paymentReasonField.stringValue]) return NO;
    return YES;
}
-(void)updateObject
{
    Payment * payment = self.payment;
    payment.account = self.accountPopupButton.selectedItem.representedObject;
    payment.reason = self.paymentReasonField.stringValue;
    payment.payeeName = self.payeeField.stringValue;
    payment.amount = @(self.amountField.doubleValue);
    NSNumber * transactionFee = self.feeField.objectValue;
    if (![transactionFee isEqualToNumber:payment.transactionFee]) {
        payment.transactionFee = self.feeField.objectValue;
        [payment recalculateNetAmountWithFee:payment.transactionFee];
    }
    payment.paymentDate = self.paymentDatePicker.dateValue;
    payment.paymentCategory = self.categoryPopup.selectedItem.representedObject;
    if (self.paymentDirection.selectedSegment == 0) {
        payment.direction = kAMCPaymentDirectionOut;
    } else {
        payment.direction = kAMCPaymentDirectionIn;
    }
}
- (IBAction)standardSelection:(id)sender {
    [self.doneButton setEnabled:[self isValid]];
}
- (IBAction)accountPopupButtonChanged:(NSPopUpButton *)sender {
    if (self.editMode == EditModeCreate) {
        [self autoUpdateFee];
    }
}
- (IBAction)directionSelectorChanged:(id)sender {
    if (self.editMode == EditModeCreate) {
        [self autoUpdateFee];
    }
}

-(void)configureBankStatementReconciliationWithPayment {
    if (self.payment.isReconciled) {
        [self.reconciledWithBankStatementCheckbox setState:NSOnState];
    } else {
        [self.reconciledWithBankStatementCheckbox setState:NSOffState];
    }
}
-(void)doneButton:(NSButton *)sender {
    [self updateObject];
    [self.payment recalculateNetAmountWithFee:self.payment.transactionFee];
    [super doneButton:sender];
}
@end
