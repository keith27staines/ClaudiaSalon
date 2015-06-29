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

@interface AMCRoleMaintenance () <NSTableViewDataSource, NSTableViewDelegate, NSTextDelegate>

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

@property (weak) IBOutlet NSButton *createRoleButton;
@property (weak) IBOutlet NSTextField *nameInstructionLabel;
@property (weak) IBOutlet NSTextField *descriptionInstructionLabel;

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
    [self.rolesTable reloadData];
    [self.usersTable reloadData];
}
- (IBAction)changeEditMode:(id)sender {
    self.editMode = (self.editModeSegmentedControl.selectedSegment==0)?EditModeView:EditModeEdit;
    [self reloadData];
}
- (IBAction)addRole:(id)sender {
    self.createRoleButton.enabled = NO;
    self.roleName.stringValue = @"";
    self.roleDescription.stringValue = @"";
    self.nameInstructionLabel.hidden = YES;
    self.descriptionInstructionLabel.hidden = YES;
    self.rolesToCopyArray = [NSMutableArray array];
    for (Role * role in self.rolesArray) {
        NSMutableDictionary * d = [@{@"role":role, @"copyThis":@NO} mutableCopy];
        [self.rolesToCopyArray addObject:d];
    }
    [self.rolesToCopyTable reloadData];
    [self presentViewControllerAsSheet:self.addRoleViewController];
}
- (IBAction)roleToCopyChanged:(id)sender {
    NSButton * button = (NSButton*)sender;
    NSInteger row = [self.rolesToCopyTable rowForView:button];
    if (row < 0) return;
    NSMutableDictionary * d = self.rolesToCopyArray[row];
    if (button.state == NSOnState) {
        d[@"copyThis"] = @YES;
    } else {
        d[@"copyThis"] = @NO;
    }
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
-(BOOL)isNewRoleNameValid:(NSString*)newRoleName {
    if (!newRoleName || newRoleName.length < 4) {
        return NO;
    }
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"name like[cd] %@",newRoleName];
    NSArray * matchingNames = [self.rolesArray filteredArrayUsingPredicate:predicate];
    if (matchingNames.count == 0) {
        return YES;
    }
    if (matchingNames.count == 1) {
        return NO;
    }
    NSAssert(NO, @"There should be only one match at most because names are supposed to be unique");
    return NO;
}
-(BOOL)isNewRoleDescriptionValid:(NSString*)newRoleDescription {
    if (!newRoleDescription || newRoleDescription.length < 4) {
        return NO;
    } else {
        return YES;
    }
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.rolesTable) {
        return self.rolesArray.count;
    }
    if (tableView == self.usersTable) {
        return self.usersArray.count;
    }
    if (tableView == self.rolesToCopyTable) {
        return self.rolesToCopyArray.count;
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
        Role * role = d[@"role"];
        checkbox.title = role.name;
        checkbox.state = ([d[@"copyThis"] isEqualToNumber:@YES])?NSOnState:NSOffState;
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
-(void)controlTextDidChange:(NSNotification *)obj {
    if (obj.object == self.roleName || obj.object == self.roleDescription) {
        BOOL roleNameValid = [self isNewRoleNameValid:self.roleName.stringValue];
        BOOL roleDescriptionValid = [self isNewRoleDescriptionValid:self.roleDescription.stringValue];
        self.createRoleButton.enabled = NO;
        self.nameInstructionLabel.hidden = YES;
        self.descriptionInstructionLabel.hidden = YES;
        if (roleNameValid && roleDescriptionValid) {
            self.createRoleButton.enabled = YES;
        } else {
            // Name and/or description validation failed
            if (!roleNameValid && obj.object == self.roleName) {
                // Failed name validation
                self.nameInstructionLabel.hidden = NO;
            }
            if (!roleDescriptionValid && obj.object == self.roleDescription) {
                // failed description validation
                self.descriptionInstructionLabel.hidden = NO;
            }
        }
    }
}
- (IBAction)createNewRole:(id)sender {
    Role * newRole = [Role newObjectWithMoc:self.documentMoc];
    newRole.name = self.roleName.stringValue;
    newRole.fullDescription = self.roleDescription.stringValue;
    for (NSDictionary * d in self.rolesToCopyArray) {
        if ([d[@"copyThis"] isEqualToNumber:@YES]) {
            Role * copyFrom = d[@"role"];
            [self addPermissionsFromRole:copyFrom toRole:newRole];
        }
    }
    [self dismissViewController:self.addRoleViewController];
    NSInteger insertIndex = self.rolesTable.selectedRow;
    [self.rolesArray insertObject:newRole atIndex:insertIndex];
    [self.rolesTable insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:insertIndex] withAnimation:NSTableViewAnimationEffectFade];
}
-(void)addPermissionsFromRole:(Role*)copyFromRole toRole:(Role*)copyToRole {
    Permission * copyToPermission;
    for (Permission * copyFromPermission in copyFromRole.permissions) {
        BusinessFunction * businessFunction = copyFromPermission.businessFunction;
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"businessFunction = %@",businessFunction];
        NSSet * existingPermissions = [copyToRole.permissions filteredSetUsingPredicate:predicate];
        NSAssert(existingPermissions.count < 2,@"Should be only one permission mapping role to business function");
        if (existingPermissions.count == 0) {
            copyToPermission = [Permission newObjectWithMoc:self.documentMoc];
            copyToPermission.role = copyToRole;
            copyToPermission.businessFunction = copyFromPermission.businessFunction;
        } else {
            copyToPermission = existingPermissions.anyObject;
        }
        if (copyFromPermission.viewAction.boolValue)   copyToPermission.viewAction   = @YES;
        if (copyFromPermission.editAction.boolValue)   copyToPermission.editAction   = @YES;
        if (copyFromPermission.createAction.boolValue) copyToPermission.createAction = @YES;
    }
}
@end
