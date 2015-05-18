//
//  EditServiceCategoryViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditServiceCategoryViewController.h"
#import "ServiceCategory+Methods.h"
#import "AMCConstants.h"
#import "AMCSalonDocument.h"

@interface EditServiceCategoryViewController ()

@end

@implementation EditServiceCategoryViewController

-(NSString *)nibName
{
    return @"EditServiceCategoryViewController";
}
-(NSString *)objectTypeAndName
{
    NSMutableString * objectTypeAndName = [@"Service Category" mutableCopy];
    if (self.objectToEdit) {
        ServiceCategory * object = (ServiceCategory*)self.objectToEdit;
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
    self.nameOfService.stringValue = @"";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument
{
    [super prepareForDisplayWithSalon:salonDocument];
    ServiceCategory * category = (ServiceCategory*)self.objectToEdit;
    switch (self.editMode) {
        case EditModeView:
        {
            self.nameOfService.stringValue  = category.name;
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
    return  @[self.nameOfService];
}
#pragma mark - NSControlTextEditingDelegate
-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    BOOL controlIsValid = NO;
    [self.doneButton setEnabled:NO];
    
    if (control == self.nameOfService) {
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
    if (![self validateName:self.nameOfService.stringValue]) return NO;
    return YES;
}
-(void)updateObject
{
    ServiceCategory * category = self.objectToEdit;
    category.name = self.nameOfService.stringValue;
    [self.salonDocument commitAndSave:nil];
}


@end
