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
@property (weak) IBOutlet NSTextField *infoLabel;
@property (weak) IBOutlet NSTextField *nameLabel;
@property (strong) IBOutlet NSView *infoView;
@property (weak) IBOutlet NSTextField *infoViewTitleLabel;
@property (weak, readonly) Role * selectedRole;
@property (weak, readonly) RoleAction * clickedRoleAction;
@property (weak) IBOutlet NSTextField *infoViewContentLabel;
@property (strong) IBOutlet NSViewController *infoViewController;
@property BOOL infoIsPresented;
@end

@implementation AMCRoleManageViewController

-(NSString *)nibName {
    return @"AMCRoleManageViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self reloadRolePopup];
    [self reloadTableData];
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
    NSButton * infoButton = sender;
    self.infoViewTitleLabel.stringValue = self.selectedRole.name;
    self.infoViewContentLabel.stringValue = self.selectedRole.fullDescription;
    [self presentInfoViewRelativeToView:infoButton];
}
- (IBAction)showActionInfo:(id)sender {
    NSButton * infoButton = sender;
    NSInteger row = [self.actionTable rowForView:sender];
    RoleAction * roleAction = self.roleActions[row];
    self.infoViewTitleLabel.stringValue = roleAction.name;
    self.infoViewContentLabel.stringValue = (roleAction.fullDescription)?roleAction.fullDescription:@"No description is available";
    [self presentInfoViewRelativeToView:infoButton];
}
-(void)presentInfoViewRelativeToView:(NSView*)view {
    if (self.infoIsPresented) {
        [self dismissViewController:self.infoViewController];
    }
    self.infoIsPresented = YES;
    [self presentViewController:self.infoViewController asPopoverRelativeToRect:view.bounds ofView:view preferredEdge:NSMaxXEdge behavior:NSPopoverBehaviorTransient];
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
    if (viewController == self.infoViewController) {
        self.infoIsPresented = NO;
    }
    [super dismissViewController:viewController];
}
@end
