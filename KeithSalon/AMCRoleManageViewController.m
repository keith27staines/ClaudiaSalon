//
//  AMCRoleManageViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCRoleManageViewController.h"
#import "Role+Methods.h"
#import "RoleAction+Methods.h"
#import "AMCSalonDocument.h"

@interface AMCRoleManageViewController () <NSTableViewDelegate, NSTableViewDataSource>
@property (weak) IBOutlet NSPopUpButton *roleSelector;
@property (weak) IBOutlet NSTableView *actionTable;
@property NSArray * roleActions;

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

@property (weak, readonly) Role * selectedRole;
@property (weak, readonly) RoleAction * clickedRoleAction;
@end

@implementation AMCRoleManageViewController

-(NSString *)nibName {
    return @"AMCRoleManageViewController";
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
    }
    [self.roleSelector selectItemAtIndex:0];
}
-(void)reloadTableData {
    self.roleActions = [RoleAction allObjectsWithMoc:self.salonDocument.managedObjectContext];
    [self.actionTable reloadData];
}
- (IBAction)roleChanged:(id)sender {
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
    NSInteger row = [self.actionTable rowForView:sender];
    RoleAction * roleAction = self.roleActions[row];
    self.actionInfoTitleLabel.stringValue = roleAction.name;
    self.actionInfoDescriptionLabel.stringValue = (roleAction.fullDescription)?roleAction.fullDescription:@"No description is available";
    self.actionVerbLabel.stringValue = roleAction.actionName;
    self.codeUnitNameLabel.stringValue = roleAction.codeUnitName;
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
    NSInteger row = [self.actionTable rowForView:sender];
    RoleAction * roleAction = self.roleActions[row];
    NSButton * checkbox = sender;
    if (checkbox.state == NSOnState) {
        [roleAction addRolesObject:self.selectedRole];
    } else {
        [roleAction removeRolesObject:self.selectedRole];
    }
    [self updateCheckbox:sender fromRoleAction:roleAction];
}
-(RoleAction *)clickedRoleAction {
    NSInteger row = self.actionTable.clickedRow;
    return self.roleActions[row];
}
-(Role *)selectedRole {
    return self.roleSelector.selectedItem.representedObject;
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.roleActions.count;
}
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    RoleAction * roleAction = self.roleActions[row];
    if ([tableColumn.identifier isEqualToString:@"actionColumn"]) {
        NSTableCellView * view = [self.actionTable makeViewWithIdentifier:@"actionView" owner:self];
        view.textField.stringValue = roleAction.name;
        NSButton * checkbox = [view viewWithTag:2];
        [self updateCheckbox:checkbox fromRoleAction:roleAction];
        return view;
    }
    return nil;
}
-(void)updateCheckbox:(NSButton*)checkbox fromRoleAction:(RoleAction*)roleAction {
    checkbox.state = ([roleAction.roles containsObject:self.selectedRole])?NSOnState:NSOffState;
    checkbox.title = (checkbox.state == NSOnState)?@"Assigned":@"Unassigned";
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
