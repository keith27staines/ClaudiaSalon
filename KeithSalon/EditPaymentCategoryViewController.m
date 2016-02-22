//
//  EditPaymentCategoryViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 14/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "EditPaymentCategoryViewController.h"
#import "PaymentCategory.h"
#import "AMCConstants.h"
#import "AMCSalonDocument.h"

@interface EditPaymentCategoryViewController ()
@property (weak) IBOutlet NSTextField *categoryName;
@end

@implementation EditPaymentCategoryViewController

-(NSString *)nibName
{
    return @"EditPaymentCategoryViewController";
}
-(NSString *)objectTypeAndName {
    return @"Payment Category";
}
-(void)clear {
    self.categoryName.stringValue = @"";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    PaymentCategory * category = (PaymentCategory*)self.objectToEdit;
    self.categoryName.stringValue  = (category.categoryName)?category.categoryName:@"";
}
-(NSArray *)editableControls {
    return  @[self.categoryName];
}
#pragma mark - NSControlTextEditingDelegate
-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    BOOL controlIsValid = NO;
    
    if (control == self.categoryName) {
        controlIsValid = [self validateName:fieldEditor.string];
    }
    return controlIsValid;
}
-(void)controlTextDidEndEditing:(NSNotification *)obj {
    [self.doneButton setEnabled:[self isValid]];
}
-(void)controlTextDidChange:(NSNotification *)obj {
    [self enableDoneButton];
}
-(BOOL)isValid {
    if (![self validateName:self.categoryName.stringValue]) return NO;
    return YES;
}
-(void)updateObject {
    PaymentCategory * category = self.objectToEdit;
    category.categoryName = self.categoryName.stringValue;
}
@end
