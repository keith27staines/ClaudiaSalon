//
//  AMCEmployeesViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 29/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCEmployeesViewController.h"
#import "AMCStaffCanDoViewController.h"
#import "Employee+Methods.h"

@interface AMCEmployeesViewController ()
@property (strong) IBOutlet AMCStaffCanDoViewController *canDoViewController;

@property (weak) IBOutlet NSSegmentedControl *activeFilter;


@property (weak) IBOutlet NSMenuItem *addEmployeeMenuItem;
@property (weak) IBOutlet NSMenuItem *viewEmployeeMenuItem;
@property (weak) IBOutlet NSMenuItem *showNotesMenuItem;
@property (weak) IBOutlet NSMenuItem *showCanDoListMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickViewEmployeeMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickShowNotesMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickShowCanDoListMenuItem;
@end

@implementation AMCEmployeesViewController

-(NSString *)nibName {
    return @"AMCEmployeesViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self activeFilterChanged:self];
}
-(NSArray *)initialSortDescriptors {
    return @[[NSSortDescriptor sortDescriptorWithKey:@"isActive" ascending:NO],[NSSortDescriptor sortDescriptorWithKey:@"fullName" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
}
#pragma mark - "PermissionDenied" Delegate
-(BOOL)permissionDeniedNeedsOKButton {
    return NO;
}

# pragma mark - Filters changed

- (IBAction)activeFilterChanged:(id)sender {
    switch (self.activeFilter.selectedSegment) {
        case 0:
            self.arrayController.filterPredicate = [NSPredicate predicateWithFormat:@"isActive = YES"];
            break;
        case 1:
            self.arrayController.filterPredicate = [NSPredicate predicateWithFormat:@"isActive = NO"];
            break;
        case 2:
            self.arrayController.filterPredicate = nil;
            break;
        default:
            self.arrayController.filterPredicate = nil;
            break;
    }
}

# pragma mark - NSMenuDelegate
-(void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == self.actionMenu) {
        menu.autoenablesItems = NO;
        self.addEmployeeMenuItem.enabled = YES;
        self.showCanDoListMenuItem.enabled = YES;
        BOOL objectIsSelected = (self.selectedObject)?YES:NO;
        self.viewEmployeeMenuItem.enabled = objectIsSelected;
        self.showNotesMenuItem.enabled = objectIsSelected;
        self.showCanDoListMenuItem.enabled = objectIsSelected;
    } else if (menu == self.rightClickMenu) {
        menu.autoenablesItems = NO;
        self.rightClickShowNotesMenuItem.enabled = YES;
        self.rightClickViewEmployeeMenuItem.enabled = YES;
        self.rightClickShowCanDoListMenuItem.enabled = YES;
    }
}
# pragma mark - Action: Show Can-Do List
- (IBAction)showCanDoList:(id)sender {
    [self showCanDoListForEmployee:self.selectedObject];
}
-(IBAction)showCanDoListForRightClick:(id)sender {
    [self showCanDoListForEmployee:self.rightClickedObject];
}
-(void)showCanDoListForEmployee:(Employee*)employee {
    self.canDoViewController.employee = employee;
    NSRect rect = [self cellRectForObject:employee column:0];
    [self.canDoViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:self.canDoViewController asPopoverRelativeToRect:rect ofView:self.dataTable preferredEdge:NSMaxXEdge behavior:NSPopoverBehaviorApplicationDefined];
}
-(void)editObjectViewController:(EditObjectViewController *)controller didCompleteCreationOfObject:(id)object {
    Employee * employee = (Employee*)controller.objectToEdit;
    employee.lastUpdatedDate = [NSDate date];
    employee.bqNeedsCoreDataExport = [NSNumber numberWithBool:YES];
    [super editObjectViewController:controller didCompleteCreationOfObject:object];
}
- (void)editObjectViewController:(EditObjectViewController *)controller didEditObject:(id)object {
    Employee * employee = (Employee*)controller.objectToEdit;
    employee.lastUpdatedDate = [NSDate date];
    employee.bqNeedsCoreDataExport = [NSNumber numberWithBool:YES];
    [super editObjectViewController:controller didEditObject:object];
}
@end
