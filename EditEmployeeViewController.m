//
//  EditEmployeeWindowController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "EditEmployeeViewController.h"
#import "AppDelegate.h"
#import "Employee.h"
#import "AMCSalaryEditorViewController.h"
#import "AMCSalonDocument.h"
#import "AMCPasswordEditor.h"
#import "AMCUserRoleEditor.h"

@interface EditEmployeeViewController ()
@property (strong) IBOutlet AMCSalaryEditorViewController *salaryEditorViewController;
@property (weak) IBOutlet NSImageView *photoView;
@property (weak,readonly) Employee * employee;
@property (strong) IBOutlet AMCPasswordEditor *passwordEditor;

@property (strong) IBOutlet AMCUserRoleEditor *userRolesEditor;

@end

@implementation EditEmployeeViewController

#pragma mark - NSWindowController overrides

-(NSString *)windowNibName
{
    return @"EditEmployeeViewController";
}
#pragma mark - editObjectViewController overrides
-(NSString*)objectTypeAndName
{
    NSMutableString * objectTypeAndName = [@"Employee" mutableCopy];
    if (self.objectToEdit) {
        Employee * object = (Employee*)self.objectToEdit;
        NSString * objectName = object.fullName;
        if (objectName) {
            [objectTypeAndName appendString:@": "];
            [objectTypeAndName appendString:objectName];
        }
    }
    return objectTypeAndName;
}
-(void)resetToObject {
    Employee * employee = self.employee;
    self.firstName.stringValue  = (employee.firstName)?employee.firstName:@"";
    self.lastName.stringValue = (employee.lastName)?employee.lastName:@"";
    self.photoView.image = employee.photo;
    self.email.stringValue = (employee.email)?employee.email:@"";
    self.mobile.stringValue = (employee.phone)?employee.phone:@"";
    self.postcode.stringValue = (employee.postcode)?employee.postcode:@"";
    self.addressLine1.stringValue = (employee.addressLine1)?employee.addressLine1:@"";
    self.addressLine2.stringValue = (employee.addressLine2)?employee.addressLine2:@"";
    self.activeMemberOfStaffCheckbox.state = (employee.isActive.boolValue)?NSOnState:NSOffState;
    NSUInteger monthOfBirth = employee.monthOfBirth.integerValue;
    NSUInteger dayOfBirth = employee.dayOfBirth.integerValue;
    [self.dayAndMonthPopupController selectMonthNumber:monthOfBirth dayNumber:dayOfBirth];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument
{
    [super prepareForDisplayWithSalon:salonDocument];
    [self resetToObject];
    switch (self.editMode) {
        case EditModeView:
        {
            [self.dayAndMonthPopupController setEnabled:NO];
            break;
        }
        case EditModeCreate:
        {
            [self.dayAndMonthPopupController setEnabled:YES];
            break;
        }
        case EditModeEdit:
        {
            [self.dayAndMonthPopupController setEnabled:YES];
            [self.dayAndMonthPopupController setEnabled:YES];
            break;
        }
    }
}
-(void)enableEditableControls:(BOOL)yn {
    [super enableEditableControls:yn];
    if (yn == YES) {
        self.photoView.enabled = YES;
        self.photoView.allowsCutCopyPaste = YES;
        self.photoView.imageFrameStyle = NSImageFrameGroove;
    } else {
        self.photoView.enabled = NO;
        self.photoView.allowsCutCopyPaste = NO;
        self.photoView.imageFrameStyle = NSImageFrameNone;
    }
}
-(NSArray *)editableControls
{
 return  @[self.firstName,
           self.lastName,
           self.email,
           self.mobile,
           self.postcode,
           self.addressLine1,
           self.addressLine2,
           self.activeMemberOfStaffCheckbox,
           self.photoView];
}
-(BOOL)isValid
{
    if (![self validateName:self.firstName.stringValue]) return NO;
    if (![self validateName:self.lastName.stringValue]) return NO;
    if (![self validateEmailAddress:self.email.stringValue]) return NO;
    if (![self validatePhoneNumber:self.mobile.stringValue]) return NO;
    return YES;
}
-(void)updateObject
{
    Employee * employee = self.employee;
    employee.firstName = self.firstName.stringValue;
    employee.lastName = self.lastName.stringValue;
    employee.phone = self.mobile.stringValue;
    employee.email = self.email.stringValue;
    employee.postcode = self.postcode.stringValue;
    employee.addressLine1 = self.addressLine1.stringValue;
    employee.addressLine2 = self.addressLine2.stringValue;
    employee.monthOfBirth = @(self.dayAndMonthPopupController.monthNumber);
    employee.dayOfBirth = @(self.dayAndMonthPopupController.dayNumber);
    employee.isActive = @(self.activeMemberOfStaffCheckbox.state == NSOnState);
    employee.photo = self.photoView.image;
    employee.lastUpdatedDate = [NSDate date];
}
#pragma mark - NSControlTextEditingDelegate
-(void)controlTextDidChange:(NSNotification *)notification
{
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
-(BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    BOOL controlIsValid = NO;
    if (control == self.firstName) {
        controlIsValid = [self validateName:fieldEditor.string];
    }
    if (control == self.lastName) {
        controlIsValid = [self validateName:fieldEditor.string];
    }
    if (control == self.email) {
        controlIsValid = [self validateEmailAddress:fieldEditor.string];
    }
    if (control == self.mobile) {
        controlIsValid = [self validatePhoneNumber:fieldEditor.string];
    }
    if (control == self.postcode) {
        controlIsValid = YES;
    }
    return controlIsValid;
}
-(void)controlTextDidEndEditing:(NSNotification *)obj
{
    // Actively reformat entered text to remove white space, etc
    if (obj.object == self.mobile) {
        self.mobile.stringValue = [self extractPhoneNumber:self.mobile.stringValue];
    }
    [self.doneButton setEnabled:[self isValid]];
}
#pragma mark - AMCDayAndMonthPopupViewControllerDelegate
-(void)dayAndMonthControllerDidUpdate:(AMCDayAndMonthPopupViewController *)dayAndMonthController
{
    
}
- (IBAction)viewSalaryButtonClicked:(id)sender {
    [self.salaryEditorViewController prepareForDisplayWithSalon:self.salonDocument];
    [self.salaryEditorViewController updateWithEmployee:self.objectToEdit forDate:[NSDate date]];
    [self presentViewControllerAsSheet:self.salaryEditorViewController];
}
- (IBAction)setPassword:(id)sender {
    self.passwordEditor.employee = self.employee;
    self.passwordEditor.firstPassword = NO;
    self.passwordEditor.resetMode = NO;
    [self.passwordEditor prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.passwordEditor];
}
- (IBAction)setRoles:(id)sender {
    self.userRolesEditor.employee = self.employee;
    self.userRolesEditor.editMode = self.editMode;
    [self.userRolesEditor prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.userRolesEditor];
}
-(Employee *)employee {
    return (Employee*)self.objectToEdit;
}
- (IBAction)picChanged:(id)sender {
}
@end
