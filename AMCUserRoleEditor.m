//
//  AMCUserRoleEditor.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCUserRoleEditor.h"
#import "Role.h"

#import "Employee.h"

@interface AMCUserRoleEditor () <NSTableViewDelegate, NSTableViewDataSource>
@property (weak) IBOutlet NSButton *hasRoleCheckbox;
@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSTextField *roleDescription;
@property (weak) IBOutlet NSTableView *dataTable;
@property (weak, readonly) Role * selectedRole;
@property (weak) IBOutlet NSButton *editModeButton;

@property NSArray * data;
@end

@implementation AMCUserRoleEditor

-(NSString *)nibName {
    return @"AMCUserRoleEditor";
}

-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.data = [Role allObjectsWithMoc:salonDocument.managedObjectContext];
    self.titleLabel.stringValue = [NSString stringWithFormat:@"Roles assigned to %@",self.employee.fullName];
    [self applyEditMode];
}
-(void)applyEditMode {
    if (self.editMode == EditModeView) {
        self.editModeButton.title = @"Edit Mode";
    } else {
        self.editModeButton.title = @"View Mode";
    }
    [self.dataTable reloadData];
    [self tableViewSelectionDidChange];
}
- (IBAction)hasRoleChanged:(id)sender {
    NSButton * checkbox = (NSButton*)sender;
    NSInteger row = [self.dataTable rowForView:checkbox];
    Role * role = self.data[row];
    if (checkbox.state == NSOnState) {
        [self.employee addRolesObject:role];
    } else {
        [self.employee removeRolesObject:role];
    }
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.data.count;
}
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    Role * role = self.data[row];
    if ([tableColumn.identifier isEqualToString:@"name"]) {
        NSTableCellView * view = [tableView makeViewWithIdentifier:@"name" owner:self];
        view.textField.stringValue = role.name;
        return view;
    }
    if ([tableColumn.identifier isEqualToString:@"checkbox"]) {
        NSButton * checkbox =  [tableView makeViewWithIdentifier:@"checkbox" owner:self];
        checkbox.state = [self.employee.roles containsObject:role]?NSOnState:NSOffState;
        if (self.editMode == EditModeView) {
            checkbox.enabled = NO;
        } else {
            checkbox.enabled = YES;
        }
        return checkbox;
    }
    return nil;
}
-(Role*)selectedRole {
    NSInteger row = self.dataTable.selectedRow;
    if (row < 0 || row == NSNotFound) {
        return nil;
    }
    return self.data[row];
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    [self tableViewSelectionDidChange];
}
-(void)tableViewSelectionDidChange {
    if (self.selectedRole) {
        self.roleDescription.stringValue = self.selectedRole.fullDescription;
    } else {
        self.roleDescription.stringValue = @"";
    }
}
- (IBAction)changeEditMode:(id)sender {
    if (self.editMode == EditModeView) {
        self.editMode = EditModeEdit;
    } else {
        self.editMode = EditModeView;
    }
    [self applyEditMode];
}
@end
