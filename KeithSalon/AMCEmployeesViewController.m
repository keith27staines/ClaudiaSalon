//
//  AMCEmployeesViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 29/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCEmployeesViewController.h"
#import "AMCStaffCanDoViewController.h"

@interface AMCEmployeesViewController ()
@property (strong) IBOutlet AMCStaffCanDoViewController *canDoViewController;
@property (weak) IBOutlet NSMenuItem *addEmployeeMenuItem;
@property (weak) IBOutlet NSMenuItem *viewEmployeeMenuItem;
@property (weak) IBOutlet NSMenuItem *showNotesMenuItem;
@property (weak) IBOutlet NSMenuItem *showCanDoListMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickViewEmployeeMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickShowNotesMenuItem;
@end

@implementation AMCEmployeesViewController

-(NSString *)nibName {
    return @"AMCEmployeesViewController";
}
-(NSArray *)initialSortDescriptors {
    return @[[NSSortDescriptor sortDescriptorWithKey:@"isActive" ascending:NO],[NSSortDescriptor sortDescriptorWithKey:@"fullName" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
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
    } else if (menu == self.rightClickMenu) {
        menu.autoenablesItems = NO;
        self.rightClickShowNotesMenuItem.enabled = YES;
        self.rightClickViewEmployeeMenuItem.enabled = YES;
    }
}
# pragma mark - Action: Show Can-Do List
- (IBAction)showCanDoList:(id)sender {
    [self.canDoViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:self.canDoViewController asPopoverRelativeToRect:self.actionButton.bounds ofView:self.actionButton preferredEdge:NSMaxXEdge behavior:NSPopoverBehaviorTransient];
}

@end
