//
//  EditPaymentCategoryViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 14/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "EditAccountancyGroupViewController.h"
#import "AccountingPaymentGroup+Methods.h"
#import "AMCConstants.h"
#import "AMCSalonDocument.h"
@interface EditAccountancyGroupViewController ()
@property (weak) IBOutlet NSTextField *nameField;
@end

@implementation EditAccountancyGroupViewController

-(NSString *)nibName
{
    return @"EditAccountancyGroupViewController";
}
-(NSString *)objectTypeAndName
{
    NSMutableString * objectTypeAndName = [@"Accounting Group" mutableCopy];
    if (self.objectToEdit) {
        AccountingPaymentGroup * object = (AccountingPaymentGroup*)self.objectToEdit;
        NSString * objectName = object.name;
        if (objectName) {
            [objectTypeAndName appendString:@": "];
            [objectTypeAndName appendString:objectName];
        }
    }
    return objectTypeAndName;
}
-(void)clear
{
    self.nameField.stringValue = @"";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument
{
    [super prepareForDisplayWithSalon:salonDocument];
    AccountingPaymentGroup * group = (AccountingPaymentGroup*)self.objectToEdit;
    self.nameField.stringValue  = (group.name)?group.name:@"";
}
-(NSArray *)editableControls
{
    return  @[self.nameField];
}
#pragma mark - NSControlTextEditingDelegate
-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    BOOL controlIsValid = NO;
    
    if (control == self.nameField) {
        controlIsValid = [self validateName:fieldEditor.string];
    }
    return controlIsValid;
}
-(void)controlTextDidEndEditing:(NSNotification *)obj
{
    [self.doneButton setEnabled:[self isValid]];
}
-(void)controlTextDidChange:(NSNotification *)obj {
    [self enableDoneButton];
}
-(BOOL)isValid
{
    if (![self validateName:self.nameField.stringValue]) return NO;
    return YES;
}
-(void)updateObject
{
    AccountingPaymentGroup * group = self.objectToEdit;
    group.name = self.nameField.stringValue;
}

@end
