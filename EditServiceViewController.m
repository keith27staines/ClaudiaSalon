//
//  EditServiceViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 22/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditServiceViewController.h"
#import "AMCConstants.h"
#import "Service+Methods.h"
#import "Product+Methods.h"
#import "ObjectSelectorViewController.h"
#import "AMCSalonDocument.h"

@interface EditServiceViewController ()
{
    NSMutableArray * _products;
}
@property NSMutableArray * products;
@property (readonly) Service * service;
@end

@implementation EditServiceViewController

-(void)cancelButton:(NSButton *)sender {
    [super cancelButton:sender];
}
-(NSString *)nibName
{
    return @"EditServiceViewController";
}
-(NSString *)objectTypeAndName
{
    NSMutableString * objectTypeAndName = [@"Service" mutableCopy];
    if (self.objectToEdit) {
        Service * object = (Service*)self.objectToEdit;
        NSString * objectName = object.name;
        if (objectName) {
            [objectTypeAndName appendString:@": "];
            [objectTypeAndName appendString:objectName];
        }
    }
    return objectTypeAndName;
}
-(Service*)service
{
    return (Service*)self.objectToEdit;
}
-(void)clear
{
    [self setObjectToEdit:self.objectToEdit];
}
-(void)setObjectToEdit:(id)objectToEdit
{
    [super setObjectToEdit:objectToEdit];
    Service * service = objectToEdit;
    self.products = [[service.product allObjects] mutableCopy];
    [self deluxeChanged:self.deluxeCheckbox];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument
{
    [super prepareForDisplayWithSalon:salonDocument];
    Service * service = self.service;
    self.nameField.stringValue = (service.name)?service.name : @"";
    self.timeRequired.stringValue = (service.expectedTimeRequired.stringValue)?service.expectedTimeRequired.stringValue:@"";
    self.nominalPrice.stringValue = (service.nominalCharge.stringValue)?service.nominalCharge.stringValue:@"";
    [self.deluxeCheckbox setState:((service.deluxe.boolValue)?NSOnState:NSOffState)];
    switch (self.editMode) {
        case EditModeView:
        {
            [self.deluxeCheckbox setEnabled:NO];
            [self.priceSlider setEnabled:NO];
            break;
        }
        case EditModeCreate:
        {
            [self.deluxeCheckbox setEnabled:YES];
            [self.priceSlider setEnabled:YES];
            break;
        }
        case EditModeEdit:
        {
            [self.deluxeCheckbox setEnabled:YES];
            [self.priceSlider setEnabled:YES];
            break;
        }
    }
    [self setPriceControls];
    [self deluxeChanged:self];
}
-(void)setPriceControls
{
    Service * service = self.service;
    self.minimumPrice.stringValue = [NSString stringWithFormat:@"£%@",service.minimumCharge];
    self.nominalPrice.stringValue = [NSString stringWithFormat:@"£%@",service.nominalCharge];
    self.maximumPrice.stringValue = [NSString stringWithFormat:@"£%@",service.maximumCharge];
    self.priceSlider.doubleValue = service.nominalCharge.doubleValue;
    self.priceSlider.minValue = service.minimumCharge.doubleValue;
    self.priceSlider.maxValue = service.maximumCharge.doubleValue;
    self.minimumPrice.stringValue = [NSString stringWithFormat:@"£%@",service.minimumCharge];
    self.maximumPrice.stringValue = [NSString stringWithFormat:@"£%@",service.maximumCharge];
    self.nominalPrice.stringValue = [NSString stringWithFormat:@"£%@",service.nominalCharge];
}
-(NSArray *)editableControls
{
    return  @[self.nameField,
              self.timeRequired,
              self.minimumPrice,
              self.nominalPrice,
              self.maximumPrice];
}

#pragma mark - NSControlTextEditingDelegate
-(void)controlTextDidChange:(NSNotification *)obj {
    [self enableDoneButton];
}
-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    BOOL controlIsValid = NO;
    
    if (control == self.nameField) {
        controlIsValid = [self validateName:fieldEditor.string];
    }
    if (control == self.timeRequired) {
        controlIsValid = YES;
    }
    if (control == self.nominalPrice || control == self.minimumPrice || control == self.maximumPrice) {
        controlIsValid = YES;
    }
    [self enableDoneButton];
    return controlIsValid;
}
-(void)controlTextDidEndEditing:(NSNotification *)obj
{
    [self enableDoneButton];
}
-(BOOL)isValid
{
    if (![self validateName:self.nameField.stringValue]) return NO;
    double nominal = self.nominalPrice.doubleValue;
    double minimum = self.minimumPrice.doubleValue;
    double maximum = self.maximumPrice.doubleValue;
    BOOL named = self.nameField.stringValue.length;
    if (named && nominal > 0.01 & nominal >= minimum && nominal <= maximum) {
        return YES;
    }
    return NO;
}
-(void)updateObject
{
    Service * service = self.objectToEdit;
    service.name = self.nameField.stringValue;
    service.nominalCharge = @(self.nominalPrice.integerValue);
    service.expectedTimeRequired = @(self.timeRequired.integerValue);
    service.product = [NSSet setWithArray:self.products];
}
- (IBAction)minimumPriceChanged:(id)sender {
    double minPrice = self.minimumPrice.doubleValue;
    double maxPrice = self.maximumPrice.doubleValue;
    double nominalPrice = self.nominalPrice.doubleValue;
    minPrice = floor(minPrice);
    if (minPrice < 0) {
        minPrice = 0;
    }
    if (minPrice > maxPrice) {
        maxPrice = minPrice;
    }
    if (minPrice > nominalPrice) {
        nominalPrice = minPrice;
    }

    self.service.minimumCharge = @(minPrice);
    self.service.maximumCharge = @(maxPrice);
    self.service.nominalCharge = @(nominalPrice);
    [self setPriceControls];
    [self enableDoneButton];
}
- (IBAction)maximumPriceChanged:(id)sender {
    double minPrice = self.minimumPrice.doubleValue;
    double maxPrice = self.maximumPrice.doubleValue;
    double nominalPrice = self.nominalPrice.doubleValue;
    maxPrice = ceil(maxPrice);
    if (maxPrice < 0) {
        maxPrice = 0;
    }
    if (maxPrice < minPrice) {
        minPrice = maxPrice;
    }
    if (maxPrice < nominalPrice) {
        nominalPrice = maxPrice;
    }

    self.service.minimumCharge = @(minPrice);
    self.service.maximumCharge = @(maxPrice);
    self.service.nominalCharge = @(nominalPrice);
    [self setPriceControls];
    [self enableDoneButton];
}

- (IBAction)nominalPriceChanged:(id)sender {
    double minPrice = self.minimumPrice.doubleValue;
    double maxPrice = self.maximumPrice.doubleValue;
    double nominalPrice = ((NSControl*)(sender)).doubleValue;
    nominalPrice = round(nominalPrice);
    if (nominalPrice < minPrice) {
        minPrice = nominalPrice;
    }
    if (nominalPrice > maxPrice) {
        maxPrice = nominalPrice;
    }
    self.service.minimumCharge = @(minPrice);
    self.service.maximumCharge = @(maxPrice);
    self.service.nominalCharge = @(nominalPrice);
    [self setPriceControls];
    [self enableDoneButton];
}

- (IBAction)deluxeChanged:(id)sender {
    if (self.deluxeCheckbox.state == NSOnState) {
        [self.deluxeBadge setHidden:NO];
    } else {
        [self.deluxeBadge setHidden:YES];
    }
}

@end
