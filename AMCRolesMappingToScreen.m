//
//  AMCRolesMappingToScreen.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCRolesMappingToScreen.h"
#import "AMCSalonDocument.h"
#import "Role+Methods.h"
#import "BusinessFunction+Methods.h"
#import "Employee+Methods.h"

@interface AMCRolesMappingToScreen () <NSTableViewDataSource, NSTableViewDelegate>
@property (weak) IBOutlet NSSegmentedControl *editViewSegmentedControl;
@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSTableView *dataTable;
@property (strong) NSMutableArray * roleArray;
@property (strong) NSMutableArray * filteredRoles;
@property EditMode editMode;
@property (weak) IBOutlet NSSegmentedControl *filterSegmentedControl;
@property (weak) IBOutlet NSSegmentedControl *editModeSegmentedControl;
@property (strong) IBOutlet NSViewController *infoViewController;
@property BOOL infoShown;
@property (weak) IBOutlet NSTextField *popupRoleNameLabel;
@property (weak) IBOutlet NSTextField *popupRoleDescriptionLabel;

@end

@interface AMCRolesMappingToScreen()
{
    EditMode _editMode;
}

@end

@implementation AMCRolesMappingToScreen

-(NSString *)nibName {
    return @"AMCRolesMappingToScreen";
}
- (IBAction)filtersChanged:(id)sender {
    switch (self.filterSegmentedControl.selectedSegment) {
        case 0:
            self.filteredRoles = [self.roleArray mutableCopy];
            break;
        case 1:
            if (self.currentUser) {
                self.filteredRoles = [[self.roleArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"any employeesInRole = %@",self.currentUser]] mutableCopy];
            } else {
                self.filteredRoles = [@[self.salonDocument.salon.basicUserRole] mutableCopy];
            }
            break;
    }
    [self.dataTable reloadData];
}
-(EditMode)editMode {
    return _editMode;
}
-(void)setEditMode:(EditMode)editMode {
    _editMode = editMode;
    [self.editModeSegmentedControl selectSegmentWithTag:0];
    [self.dataTable reloadData];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.editMode = EditModeView;
    self.editViewSegmentedControl.selectedSegment = 0;
    self.roleArray = [[self.mappedbusinessFunction mappedRoles] mutableCopy];
    self.filterSegmentedControl.selectedSegment = 1;
    [self filtersChanged:self];
    NSString * currentUserString = self.currentUser.fullName;
    if (!currentUserString) {
        currentUserString = @"Basic User's";
    }
    currentUserString = [currentUserString stringByAppendingString:@" roles"];
    [self.filterSegmentedControl setLabel:currentUserString forSegment:1];
    self.infoShown = NO;
    self.titleLabel.stringValue = [@"Permissions for: " stringByAppendingString:self.mappedbusinessFunction.functionName];
}
- (IBAction)editViewSegmentedControl:(id)sender {
    NSSegmentedControl * segmented = sender;
    if (segmented.selectedSegment == 0) {
        self.editMode = EditModeView;
    } else {
        self.editMode = EditModeEdit;
    }
    [self.dataTable reloadData];
}
- (IBAction)addButton:(id)sender {
}
- (IBAction)removeButton:(id)sender {
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.filteredRoles.count;
}
- (IBAction)showInfo:(id)sender {
    NSButton * button = sender;
    [self ensureInfoNotShown];
    NSInteger row = [self.dataTable rowForView:button];
    Role * role = self.filteredRoles[row];
    self.popupRoleNameLabel.stringValue = [role.name stringByAppendingString:@" role"];
    self.popupRoleDescriptionLabel.stringValue = role.fullDescription;
    self.infoShown = YES;
    [self presentViewController:self.infoViewController asPopoverRelativeToRect:button.bounds ofView:button preferredEdge:NSMaxXEdge behavior:NSPopoverBehaviorTransient];
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    Role * role = self.filteredRoles[row];
    if ([tableColumn.identifier isEqualToString:@"roleNameColumn"]) {
        NSTableCellView * view = [tableView makeViewWithIdentifier:@"roleNameView" owner:self];
        view.textField.stringValue = role.name;
        return view;
    }
    if ([tableColumn.identifier isEqualToString:@"actionsColumn"]) {
        NSView * view = [tableView makeViewWithIdentifier:@"actionsView" owner:self];
        NSButton * viewCheckbox = [view viewWithTag:0];
        NSButton * editCheckbox = [view viewWithTag:1];
        NSButton * createCheckbox = [view viewWithTag:2];
        viewCheckbox.state = ([role allowsBusinessFunction:self.mappedbusinessFunction verb:@"View"]).boolValue?NSOnState:NSOffState;
        editCheckbox.state = ([role allowsBusinessFunction:self.mappedbusinessFunction verb:@"Edit"]).boolValue?NSOnState:NSOffState;
        createCheckbox.state = ([role allowsBusinessFunction:self.mappedbusinessFunction verb:@"Create"]).boolValue?NSOnState:NSOffState;
        viewCheckbox.enabled = (self.editMode==EditModeEdit)?YES:NO;
        editCheckbox.enabled = viewCheckbox.enabled;
        createCheckbox.enabled = viewCheckbox.enabled;
        return view;
    }
    return nil;
}
-(void)ensureInfoNotShown {
    if (self.infoShown) {
        [self dismissViewController:self.infoViewController];
    }
}
-(void)dismissViewController:(NSViewController *)viewController {
    [super dismissViewController:viewController];
    self.infoShown = NO;
}
@end
