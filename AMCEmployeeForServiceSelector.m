//
//  AMCEmployeeForServiceSelector.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/02/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCEmployeeForServiceSelector.h"
#import "Employee.h"
#import "Service.h"
@interface AMCEmployeeForServiceSelector ()

@property (weak) IBOutlet NSTextField *serviceNameTextField;
@property (weak) IBOutlet NSPopUpButton *staffSelectorPopupButton;
@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *doneButton;

@end

@implementation AMCEmployeeForServiceSelector

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self populateStaffPopup];
    self.serviceNameTextField.stringValue = self.service.name;
}
-(void)populateStaffPopup {
    NSArray * staffWhoCan = [Employee employeesWhoCanPerformService:self.service withMoc:self.documentMoc];
    [self.staffSelectorPopupButton removeAllItems];
    NSMenuItem * item = nil;
    switch (staffWhoCan.count) {
        case 0:
        {
            item = [[NSMenuItem alloc] init];
            item.title = @"Assign a member of staff later";
            item.tag = 1;
            [self.staffSelectorPopupButton.menu addItem:item];
            [self.staffSelectorPopupButton selectItem:item];
            break;
        }
        default:
        {
            item = [[NSMenuItem alloc] init];
            item.title = @"Select a member of staff";
            [self.staffSelectorPopupButton.menu addItem:item];
            [self.staffSelectorPopupButton selectItem:item];
            item = [[NSMenuItem alloc] init];
            item.title = @"Assign a member of staff later";
            item.tag = 1;
            [self.staffSelectorPopupButton.menu addItem:item];
            
            for (Employee * employee in staffWhoCan) {
                item = [[NSMenuItem alloc] init];
                item.representedObject = employee;
                item.title = employee.fullName;
                [self.staffSelectorPopupButton.menu addItem:item];
                if (employee == self.employee) {
                    [self.staffSelectorPopupButton selectItem:item];
                }
            }
            break;
        }
    }
    [self changedStaff:self];
}
- (IBAction)cancelButton:(id)sender {
    self.cancelled = YES;
    [self dismissController:sender];
}
- (IBAction)doneButton:(id)sender {
    self.cancelled = NO;
    [self dismissController:sender];
}
- (IBAction)changedStaff:(id)sender {
    NSMenuItem * selectedItem = self.staffSelectorPopupButton.selectedItem;
    if (selectedItem.representedObject || selectedItem.tag == 1) {
        self.doneButton.enabled = YES;
        self.employee = selectedItem.representedObject;
    } else {
        self.doneButton.enabled = NO;
        self.employee = nil;
    }
}
@end
