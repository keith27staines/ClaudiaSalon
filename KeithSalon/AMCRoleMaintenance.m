//
//  AMCRoleMaintenance.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
@class AMCPermissionsForRoleEditor;

#import "AMCRoleMaintenance.h"
#import "Permission+Methods.h"
#import "BusinessFunction+Methods.h"
#import "Employee+Methods.h"
#import "Role+Methods.h"
#import "AMCPermissionsForRoleEditor.h"

@interface AMCRoleMaintenance () <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSSegmentedControl *editModeSegmentedControl;
@property (weak) IBOutlet NSTableView *rolesTable;
@property (weak) IBOutlet NSTableView *usersTable;
@property (weak) IBOutlet NSButton *addRoleButton;
@property (weak) IBOutlet NSButton *removeRoleButton;
@property (weak) IBOutlet NSButton *mapRolesToScreensButton;

@property (strong) IBOutlet NSViewController *addRoleViewController;

@property (strong) IBOutlet AMCPermissionsForRoleEditor *permissionsForRoleEditor;
@property (weak) IBOutlet NSTableView *rolesToCopyTable;
@property NSMutableArray * rolesArray;
@property NSMutableArray * usersArray;
@property NSMutableArray * rolesToCopyArray;
@property (readonly) Role * selectedRole;
@property (weak) IBOutlet NSTextField *roleName;
@property (weak) IBOutlet NSTextField *roleDescription;

@end

@implementation AMCRoleMaintenance

-(NSString *)nibName {
    return @"AMCRoleMaintenance";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    switch (self.editMode) {
        case EditModeView: {
            [self.editModeSegmentedControl selectSegmentWithTag:0];
            break;
        }
        case EditModeEdit: {
            [self.editModeSegmentedControl selectSegmentWithTag:1];
            break;
        }
        case EditModeCreate: {
            [self.editModeSegmentedControl selectSegmentWithTag:1];
            break;
        }
    }
    [self reloadData];
}
-(NSArray*)editableControls {
    return @[self.addRoleButton,self.removeRoleButton,self.mapRolesToScreensButton];
}
-(void)reloadData {
    for (NSControl * control in [self editableControls]) {
        control.enabled = self.editMode != EditModeView;
    }
    self.usersArray = [[Employee allActiveEmployeesWithMoc:self.documentMoc] mutableCopy];
    self.rolesArray = [[Role allObjectsWithMoc:self.documentMoc] mutableCopy];
    self.rolesToCopyArray = [NSMutableArray array];
    for (Role * role in self.rolesArray) {
        NSDictionary * d = @{@"name":role.name, @"copyThis":@NO};
        [self.rolesToCopyArray addObject:d];
    }
    [self.rolesTable reloadData];
    [self.usersTable reloadData];
}
- (IBAction)changeEditMode:(id)sender {
    self.editMode = (self.editModeSegmentedControl.selectedSegment==0)?EditModeView:EditModeEdit;
    [self reloadData];
}
- (IBAction)addRole:(id)sender {
    [self presentViewControllerAsSheet:self.addRoleViewController];
}
- (IBAction)removeRole:(id)sender {
}
- (IBAction)showPermissionsForRoleEditor:(id)sender {
    [self.permissionsForRoleEditor prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.permissionsForRoleEditor];
}
-(Role*)selectedRole {
    NSInteger row = self.rolesTable.selectedRow;
    if (row < 0) return nil;
    return self.rolesArray[row];
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.rolesTable) {
        return self.rolesArray.count;
    }
    if (tableView == self.usersTable) {
        return self.usersArray.count;
    }
    if (tableView == self.rolesToCopyTable) {
        return self.rolesArray.count;
    }
    NSAssert(NO, @"Number of rows not specified for table %@",tableView);
    return 0;
}
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.rolesTable) {
        Role * role = self.rolesArray[row];
        NSTableCellView * view = [self.rolesTable makeViewWithIdentifier:@"mainCell" owner:self];
        view.textField.stringValue = role.name;
        return view;
    }
    if (tableView == self.usersTable) {
        Employee * user = self.usersArray[row];
        if ([tableColumn.identifier isEqualToString:@"users"]) {
            NSTableCellView * view = [self.usersTable makeViewWithIdentifier:@"users" owner:self];
            view.textField.stringValue = user.fullName;
            return view;
        } else if ([tableColumn.identifier isEqualToString:@"inRole"]) {
            NSTableCellView * view = [self.usersTable makeViewWithIdentifier:@"inRole" owner:self];
            NSButton * checkbox = [view viewWithTag:0];
            checkbox.state = ([user.roles containsObject:self.selectedRole])?NSOnState:NSOffState;
            checkbox.enabled = (self.editMode == EditModeEdit)?YES:NO;
            return view;
        }
    }
    if (tableView == self.rolesToCopyTable) {
        NSDictionary * d = self.rolesToCopyArray[row];
        NSTableCellView * view = [self.rolesToCopyTable makeViewWithIdentifier:@"mainCell" owner:self];
        NSButton * checkbox = [view viewWithTag:0];
        checkbox.title = d[@"name"];
        checkbox.state = ([d[@"copyThis"] isEqual:@YES])?NSOnState:NSOffState;
        return view;
    }
    NSAssert(NO, @"No view for row");
    return nil;
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (notification.object == self.rolesTable) {
        [self.usersTable reloadData];
    }
}
- (IBAction)cancelCreateNewRole:(id)sender {
    [self dismissViewController:self.addRoleViewController];
}

- (IBAction)createNewRole:(id)sender {
    Role * role = [Role newObjectWithMoc:self.documentMoc];
    role.name = self.roleName.stringValue;
    role.fullDescription = self.roleDescription.stringValue;
    for (NSDictionary * d in self.rolesToCopyArray) {
        if ([d[@"copyThis"] isEqualToNumber:@YES]) {
            Role * copyFrom = d[@"role"];
            for (Permission * permission in copyFrom.permissions) {

            }
        }
    }
    [self dismissViewController:self.addRoleViewController];
    NSInteger insertIndex = self.rolesTable.selectedRow;
    [self.rolesArray insertObject:role atIndex:insertIndex];
    [self.rolesTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:insertIndex] withAnimation:NSTableViewAnimationEffectFade];
}

@end
