//
//  EditProductViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditProductViewController.h"
#import "Product+Methods.h"
#import "AMCConstants.h"
#import "AMCSalonDocument.h"

@interface EditProductViewController ()

@end

@implementation EditProductViewController
-(NSString *)nibName
{
    return @"EditProductViewController";
}
-(NSString *)objectName
{
    return @"Product";
}

-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument
{
    [super prepareForDisplayWithSalon:salonDocument];
    Product * product = (Product*)self.objectToEdit;
    switch (self.editMode) {
        case EditModeView:
        {
            self.brandName.stringValue  = product.brandName;
            self.productType.stringValue = product.productType;
            break;
        }
        case EditModeCreate:
        {
            break;
        }
        case EditModeEdit:
        {
            break;
        }
    }
}

-(NSArray *)editableControls
{
    return  @[self.brandName,
              self.productType];
}

#pragma mark - NSControlTextEditingDelegate
-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    BOOL controlIsValid = NO;
    [self.doneButton setEnabled:NO];

    if (control == self.brandName) {
        controlIsValid = [self validateName:fieldEditor.string];
    }
    if (control == self.productType) {
        controlIsValid = [self validateName:fieldEditor.string];
    }

    [self.doneButton setEnabled:[self isValid]];
    return controlIsValid;
}
-(void)controlTextDidEndEditing:(NSNotification *)obj
{
    [self.doneButton setEnabled:[self isValid]];
}
-(BOOL)isValid
{
    if (![self validateName:self.brandName.stringValue]) return NO;
    if (![self validateName:self.productType.stringValue]) return NO;
    return YES;
}
-(void)updateObject
{
    Product * product = self.objectToEdit;
    product.brandName = self.brandName.stringValue;
    product.productType = self.productType.stringValue;
    [self.salonDocument commitAndSave:nil];
}



@end
