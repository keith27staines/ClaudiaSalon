//
//  EditServiceCategoryViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditServiceCategoryViewController.h"
#import "ServiceCategory.h"
#import "AMCConstants.h"
#import "AMCSalonDocument.h"

@interface EditServiceCategoryViewController ()

@end

@implementation EditServiceCategoryViewController

-(NSString *)nibName {
    return @"EditServiceCategoryViewController";
}
-(NSString *)objectTypeAndName {
    return @"Service Category";
}
-(void)clear {
    self.nameOfService.stringValue = @"";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    ServiceCategory * category = (ServiceCategory*)self.objectToEdit;
    self.nameOfService.stringValue  = (category.name)?category.name:@"";
}
-(NSArray *)editableControls {
    return  @[self.nameOfService];
}
#pragma mark - NSControlTextEditingDelegate
-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    BOOL controlIsValid = NO;
    
    if (control == self.nameOfService) {
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
    if (![self validateName:self.nameOfService.stringValue]) return NO;
    return YES;
}
-(void)updateObject
{
    ServiceCategory * category = self.objectToEdit;
    category.name = self.nameOfService.stringValue;
}


@end
