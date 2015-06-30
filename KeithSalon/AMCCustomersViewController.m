//
//  AMCCustomersViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 29/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCCustomersViewController.h"
#import "AMCDayAndMonthPopupViewController.h"

@interface AMCCustomersViewController ()
@property (weak) IBOutlet NSButton *clearFiltersButton;
@property (weak) IBOutlet NSTextField *firstNameFilter;
@property (weak) IBOutlet NSTextField *lastNameFilter;
@property (weak) IBOutlet NSTextField *emailAddressFilter;
@property (weak) IBOutlet NSTextField *phoneFilter;
@property (weak) IBOutlet AMCDayAndMonthPopupViewController *birthdayPopupFilter;

@property (weak) IBOutlet NSMenuItem *addCustomerMenuItem;
@property (weak) IBOutlet NSMenuItem *editCustomerMenuItem;
@property (weak) IBOutlet NSMenuItem *showNotesMenuItem;

@property (weak) IBOutlet NSMenuItem *rightClickEditCustomerMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickShowNotesMenuItem;

@end

@implementation AMCCustomersViewController

-(NSString *)nibName {
    return @"AMCCustomersViewController";
}
-(void)viewDidLoad {
    [super viewDidLoad];
}
-(NSArray *)initialSortDescriptors {
    return @[[NSSortDescriptor sortDescriptorWithKey:@"fullName" ascending:YES]];
}
#pragma mark - "PermissionDenied" Delegate
-(BOOL)permissionDeniedNeedsOKButton {
    return NO;
}
#pragma mark - AMCDayAndMonthPopupControllerDelegate
-(void)dayAndMonthControllerDidUpdate:(AMCDayAndMonthPopupViewController *)dayAndMonthController
{
    if (dayAndMonthController == self.birthdayPopupFilter) {
        self.arrayController.fetchPredicate = [self buildPredicateFromCustomerFilters];
    }
}
#pragma mark - NSMenuDelegate 
-(void)menuNeedsUpdate:(NSMenu*)menu {
    menu.autoenablesItems = NO;
    if (menu == self.actionMenu) {
        self.addCustomerMenuItem.enabled = YES;
        BOOL selectedObjectExists = (self.selectedObject)?YES:NO;
        self.editCustomerMenuItem.enabled = selectedObjectExists;
        self.showNotesMenuItem.enabled = selectedObjectExists;
    } else if (menu == self.rightClickMenu) {
        self.rightClickEditCustomerMenuItem.enabled = YES;
        self.rightClickShowNotesMenuItem.enabled = YES;
    }
}
#pragma mark - NSControlTextEditingDelegate
-(void)controlTextDidChange:(NSNotification *)notification
{
    if (notification.object == self.firstNameFilter) {
        self.firstNameFilter.stringValue = [self.firstNameFilter.stringValue capitalizedString];
    }
    if (notification.object == self.lastNameFilter) {
        self.lastNameFilter.stringValue = [self.lastNameFilter.stringValue capitalizedString];
    }
    self.arrayController.fetchPredicate = [self buildPredicateFromCustomerFilters];
    [self.dataTable deselectAll:self];
}
#pragma mark - Customer tab filters
- (IBAction)clearCustomerFilters:(id)sender {
    [self clearCustomersFilterSet];
    self.arrayController.fetchPredicate = [self buildPredicateFromCustomerFilters];
    [self.dataTable deselectAll:self];
}

-(NSSet*)customersFilterSet
{
    return [NSSet setWithObjects:
            self.firstNameFilter,
            self.lastNameFilter,
            self.phoneFilter,
            self.emailAddressFilter,
            self.birthdayPopupFilter ,nil];
}
-(void)clearCustomersFilterSet
{
    self.firstNameFilter.stringValue = @"";
    self.lastNameFilter.stringValue = @"";
    self.phoneFilter.stringValue = @"";
    self.emailAddressFilter.stringValue = @"";
    [self.birthdayPopupFilter selectMonthNumber:0 dayNumber:0];
}
-(NSPredicate*)buildPredicateFromCustomerFilters
{
    NSMutableArray * predicateArray = [NSMutableArray array];
    // First Name
    if (self.firstNameFilter.stringValue.length > 0) {
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"firstName beginswith[cd] %@",self.firstNameFilter.stringValue]];
    }
    // Last Name
    if (self.lastNameFilter.stringValue.length > 0) {
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"lastName beginswith[cd] %@",self.lastNameFilter.stringValue]];
    }
    // email
    if (self.emailAddressFilter.stringValue.length > 0) {
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"email beginswith[cd] %@",self.emailAddressFilter.stringValue]];
    }
    // phone
    if (self.phoneFilter.stringValue.length > 0) {
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"phone beginswith[cd] %@",self.phoneFilter.stringValue]];
    }
    // day of birth
    if (self.birthdayPopupFilter.dayNumber > 0) {
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"dayOfBirth = %@",@(self.birthdayPopupFilter.dayNumber)]];
    }
    // month of birth
    if (self.birthdayPopupFilter.monthNumber > 0) {
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"monthOfBirth = %@",@(self.birthdayPopupFilter.monthNumber)]];
    }
    return [NSCompoundPredicate andPredicateWithSubpredicates:predicateArray];
}
@end
