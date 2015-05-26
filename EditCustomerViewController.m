//
//  EditCustomerWindowController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditCustomerViewController.h"
#import "Customer+Methods.h"
#import "Sale+Methods.h"
#import "SaleItem+Methods.h"
#import "Payment+Methods.h"
#import "AMCConstants.h"
#import "AMCSalonDocument.h"

@interface EditCustomerViewController ()

@property NSArray * salesArray;
@end

@implementation EditCustomerViewController

-(NSString *)nibName
{
    return @"EditCustomerViewController";
}
-(NSString *)objectTypeAndName
{
    NSMutableString * objectTypeAndName = [@"Customer" mutableCopy];
    if (self.objectToEdit) {
        Customer * object = (Customer*)self.objectToEdit;
        NSString * objectName = object.fullName;
        if (objectName) {
            [objectTypeAndName appendString:@": "];
            [objectTypeAndName appendString:objectName];
        }
    }
    return objectTypeAndName;
}
-(void)setObjectToEdit:(id)objectToEdit {
    [self view];
    [super setObjectToEdit:objectToEdit];
    Customer * customer = (Customer*)self.objectToEdit;
    self.salesArray = [customer.sales allObjects];
    [self.previousVisitsTable reloadData];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument
{
    [super prepareForDisplayWithSalon:self.salonDocument];
    Customer * customer = (Customer*)self.objectToEdit;
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:NO];
    self.salesArray = [self.salesArray sortedArrayUsingDescriptors:@[sort]];
    self.firstName.stringValue  = customer.firstName;
    self.lastName.stringValue = customer.lastName;
    self.email.stringValue = customer.email;
    self.phone.stringValue = customer.phone;
    [self.dayAndMonthPopupButtonsController selectMonthNumber:customer.monthOfBirth.integerValue dayNumber:customer.dayOfBirth.integerValue];
    self.postcode.stringValue = customer.postcode;
    self.addressLine1.stringValue = customer.addressLine1;
    self.addressLine2.stringValue = customer.addressLine2;
    double amountSpent = [self amountSpent];
    double amountRefunded = [self amountRefunded];
    self.previousVisitsLabel.stringValue = [NSString stringWithFormat:@"Number of previous visits: %lu.   Amount spent: £%1.2f.   Amount refunded: £%1.2f",[customer numberOfPreviousVisits].integerValue,amountSpent,amountRefunded];

    switch (self.editMode) {
        case EditModeView:
        {
            [self.dayAndMonthPopupButtonsController setEnabled:NO];
            [self.doneButton setHidden:YES];
            break;
        }
        case EditModeCreate:
        {
            [self.dayAndMonthPopupButtonsController setEnabled:YES];
            [self.doneButton setHidden:NO];
            break;
        }
        case EditModeEdit:
        {
            [self.dayAndMonthPopupButtonsController setEnabled:YES];
            [self.doneButton setHidden:NO];
            break;
        }
    }
}
-(double)amountSpent
{
    Customer * customer = (Customer*)self.objectToEdit;
    return [customer totalMoneySpent].doubleValue;
}
-(double)amountRefunded
{
    Customer * customer = (Customer*)self.objectToEdit;
    return [customer totalMoneyRefunded].doubleValue;
}
-(NSString*)stringValueOrEmptyString:(NSString*)string
{
    if (!string || [string isEqualToString:@""]) {
        return @"";
    } else {
        return string;
    }
}

-(NSArray *)editableControls
{
    return  @[self.firstName,
              self.lastName,
              self.phone,
              self.email,
              self.postcode,
              self.addressLine1,
              self.addressLine2];
}

#pragma mark - NSTableViewDataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.salesArray.count;
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (self.salesArray.count == 0) {
        return nil;
    }
    Sale * sale = self.salesArray[row];
    if ([tableColumn.identifier isEqualToString:@"dateAndTime"]) {
        return sale.createdDate;
    }
    if ([tableColumn.identifier isEqualToString:@"actualCharge"]) {
        return [NSString stringWithFormat:@"£%1.2f",sale.actualCharge.doubleValue];
    }
    if ([tableColumn.identifier isEqualToString:@"discount"]) {
        double actualCharge = sale.actualCharge.doubleValue;
        double nominalCharge = sale.nominalCharge.doubleValue;
        if (actualCharge == nominalCharge) {
            return @"None";
        } else {
            double discount = nominalCharge - actualCharge;
            int percent = round(discount / actualCharge * 100);
            return [NSString stringWithFormat:@"£%1.2f  (%i%%)",discount,percent];
        }
    }
    if ([tableColumn.identifier isEqualToString:@"refund"]) {
        double refund = 0.0;
        for (SaleItem * saleItem in sale.saleItem) {
            if (saleItem.refund) {
                refund += saleItem.refund.amount.doubleValue;
            }
        }
        if (refund > 0) {
            return [NSString stringWithFormat:@"£%1.2f",refund];
        } else {
            return @"None";
        }
    }
    return @"";
}

#pragma mark - NSTableViewDelegate
-(void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    
}
#pragma mark - NSControlTextEditingDelegate
-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    BOOL controlIsValid = YES;
    [self.doneButton setEnabled:NO];
    if (control == self.firstName) {
        controlIsValid = [self validateName:fieldEditor.string];
    }
    if (control == self.lastName) {
        controlIsValid = YES;
    }
    if (control == self.email) {
        controlIsValid = [self validateEmailAddress:fieldEditor.string];
    }
    if (control == self.phone) {
        controlIsValid = [self validatePhoneNumber:fieldEditor.string];
    }
    [self.doneButton setEnabled:[self isValid]];
    return controlIsValid;
}
-(void)controlTextDidEndEditing:(NSNotification *)obj
{
    // Actively reformat entered text to remove white space, etc
    if (obj.object == self.phone) {
        self.phone.stringValue = [self extractPhoneNumber:self.phone.stringValue];
    }
    [self.doneButton setEnabled:[self isValid]];
}

#pragma mark - NSTextFieldDelegate
-(void)controlTextDidChange:(NSNotification *)notification {
    if (notification.object == self.firstName) {
        self.firstName.stringValue = [self.firstName.stringValue capitalizedString];
    }
    if (notification.object == self.lastName) {
        self.lastName.stringValue = [self.lastName.stringValue capitalizedString];
    }
    if (notification.object == self.addressLine1) {
        self.addressLine1.stringValue = [self.addressLine1.stringValue capitalizedString];
    }
    if (notification.object == self.addressLine2) {
        self.addressLine2.stringValue = [self.addressLine2.stringValue capitalizedString];
    }
    if (notification.object == self.postcode) {
        self.postcode.stringValue = [self.postcode.stringValue uppercaseString];
    }
    [self enableDoneButton];
}

#pragma mark - Validation
-(BOOL)isValid
{
    if (![self validateName:self.firstName.stringValue]) return NO;

    if (self.phone.stringValue.length > 0) {
        if (![self validatePhoneNumber:self.phone.stringValue]) {
            return NO;
        }
    }
    if (self.email.stringValue.length > 0) {
        if (![self validateEmailAddress:self.email.stringValue]) {
            return NO;
        }
    }
    if (self.phone.stringValue.length == 0 && self.email.stringValue.length == 0) {
        return NO;
    }
    return YES;
}
-(void)updateObject
{
    Customer * customer = (Customer*)self.objectToEdit;
    customer.firstName = self.firstName.stringValue;
    customer.lastName = self.lastName.stringValue;
    if (self.email.stringValue) {
        customer.email = self.email.stringValue;
    }
    if (self.phone.stringValue) {
        customer.phone = self.phone.stringValue;
    }
    if (self.postcode.stringValue) {
        customer.postcode = self.postcode.stringValue;
    }
    if (self.addressLine1.stringValue) {
        customer.addressLine1 = self.addressLine1.stringValue;
    }
    if (self.addressLine2) {
        customer.addressLine2 = self.addressLine2.stringValue;
    }
    customer.dayOfBirth = @(self.dayAndMonthPopupButtonsController.dayNumber);
    customer.monthOfBirth = @(self.dayAndMonthPopupButtonsController.monthNumber);
}

-(void)dayAndMonthControllerDidUpdate:(AMCDayAndMonthPopupViewController *)dayAndMonthController
{
    // Nothing to do here yet
}
@end
