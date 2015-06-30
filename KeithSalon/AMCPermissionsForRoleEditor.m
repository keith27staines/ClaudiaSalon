//
//  AMCPermissionsForRoleEditor.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCPermissionsForRoleEditor.h"
#import "Role+Methods.h"
#import "Permission+Methods.h"
#import "BusinessFunction+Methods.h"
#import "AMCSalonDocument.h"

@interface AMCPermissionsForRoleEditor () <NSTableViewDelegate, NSTableViewDataSource>
{
    __weak Role * _selectedRole;
}
@property (weak) IBOutlet NSPopUpButton *roleSelector;
@property (weak) IBOutlet NSTableView *permissionsTable;
@property NSMutableArray * permissions;

@property (strong) IBOutlet NSViewController *roleInfoViewController;
@property (weak) IBOutlet NSTextField *roleInfoTitleLabel;
@property (weak) IBOutlet NSTextField *roleInfoDescriptionLabel;
@property BOOL roleInfoIsPresented;

@property (strong) IBOutlet NSViewController *actionInfoViewController;
@property (weak) IBOutlet NSTextField *actionInfoTitleLabel;
@property (weak) IBOutlet NSTextField *actionInfoDescriptionLabel;
@property (strong) IBOutlet NSView *actionInfoView;
@property (strong) IBOutlet NSTextField *actionVerbLabel;
@property (strong) IBOutlet NSTextField * codeUnitNameLabel;
@property BOOL actionInfoIsPresented;
@property (weak, readonly) BusinessFunction * clickedBusinessFunction;

@end

@implementation AMCPermissionsForRoleEditor

-(NSString *)nibName {
    return @"AMCPermissionsForRoleEditor";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self reloadRolePopup];
    [self reloadTableData];
    self.roleInfoIsPresented = NO;
    self.actionInfoIsPresented = NO;
}
-(void)reloadRolePopup {
    [self.roleSelector removeAllItems];
    for (Role * role in [Role allObjectsWithMoc:self.salonDocument.managedObjectContext]) {
        NSMenuItem * item = [[NSMenuItem alloc] init];
        item.representedObject = role;
        item.title = role.name;
        [self.roleSelector.menu addItem:item];
        if (role == self.selectedRole) {
            [self.roleSelector selectItem:item];
        }
    }
    if (!self.selectedRole) {
        [self.roleSelector selectItemAtIndex:0];
        self.selectedRole = self.roleSelector.selectedItem.representedObject;
    }
}
-(void)reloadTableData {

    self.permissions = [[self.selectedRole.permissions allObjects] mutableCopy];
    [self.permissionsTable reloadData];
}
- (IBAction)roleChanged:(id)sender {
    self.selectedRole = self.roleSelector.selectedItem.representedObject;
    [self reloadTableData];
}
- (IBAction)showRoleInfo:(id)sender {
    [self ensurePopupNotPresented];
    NSButton * infoButton = sender;
    self.roleInfoTitleLabel.stringValue = self.selectedRole.name;
    self.roleInfoDescriptionLabel.stringValue = self.selectedRole.fullDescription;
    self.roleInfoIsPresented = YES;
    [self presentViewController:self.roleInfoViewController asPopoverRelativeToRect:infoButton.bounds ofView:infoButton preferredEdge:NSMaxXEdge behavior:NSPopoverBehaviorTransient];
}
- (IBAction)showActionInfo:(id)sender {
    [self ensurePopupNotPresented];
    NSButton * infoButton = sender;
    NSInteger row = [self.permissionsTable rowForView:sender];
    Permission * permission = self.permissions[row];
    BusinessFunction * businessFunction = permission.businessFunction;
    self.actionInfoTitleLabel.stringValue = [@"Function:" stringByAppendingString:businessFunction.functionName];
    self.actionInfoDescriptionLabel.stringValue = (businessFunction.fullDescription)?businessFunction.fullDescription:@"No description is available";
    self.codeUnitNameLabel.stringValue = businessFunction.codeUnitName;
    self.actionInfoIsPresented = YES;
    [self presentViewController:self.actionInfoViewController asPopoverRelativeToRect:infoButton.bounds ofView:infoButton preferredEdge:NSMaxXEdge behavior:NSPopoverBehaviorTransient];
}
-(void)ensurePopupNotPresented {
    if (self.roleInfoIsPresented) {
        [self dismissViewController:self.roleInfoViewController];
    }
    if (self.actionInfoIsPresented) {
        [self dismissViewController:self.actionInfoViewController];
    }
}
- (IBAction)changeAssignment:(id)sender {
    NSButton * button = (NSButton*)sender;
    NSInteger tag = button.tag;
    NSInteger row = [self.permissionsTable rowForView:button];
    Permission * permission = self.permissions[row];
    switch (tag) {
        case 2:
            permission.viewAction = @((button.state==NSOnState)?YES:NO);
            break;
        case 3:
            permission.editAction = @((button.state==NSOnState)?YES:NO);
            break;
        case 4:
            permission.createAction = @((button.state==NSOnState)?YES:NO);
            break;
    }
}
-(Permission *)clickedPermission {
    NSInteger row = self.permissionsTable.clickedRow;
    return self.permissions[row];
}
-(Role *)selectedRole {
    return _selectedRole;
}
-(void)setSelectedRole:(Role *)selectedRole {
    _selectedRole = selectedRole;
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.permissions.count;
}
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    Permission * permission = self.permissions[row];
    BusinessFunction * businessFunction = permission.businessFunction;
    if ([tableColumn.identifier isEqualToString:@"actionColumn"]) {
        NSTableCellView * view = [self.permissionsTable makeViewWithIdentifier:@"actionView" owner:self];
        view.textField.stringValue = businessFunction.functionName;
        NSButton * viewCheckbox   = [view viewWithTag:2];
        NSButton * editCheckbox   = [view viewWithTag:3];
        NSButton * createCheckbox = [view viewWithTag:4];
        viewCheckbox.state   = (permission.viewAction.boolValue)?NSOnState:NSOffState;
        editCheckbox.state   = (permission.editAction.boolValue)?NSOnState:NSOffState;
        createCheckbox.state = (permission.createAction.boolValue)?NSOnState:NSOffState;
        return view;
    }
    return nil;
}

-(void)dismissViewController:(NSViewController *)viewController {
    if (viewController == self.roleInfoViewController && self.roleInfoIsPresented) {
        self.roleInfoIsPresented = NO;
        [super dismissViewController:viewController];
    } else if (viewController == self.actionInfoViewController && self.actionInfoIsPresented) {
        self.actionInfoIsPresented = NO;
        [super dismissViewController:viewController];
    } else {
        [super dismissViewController:viewController];
    }
}
@end
