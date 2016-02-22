//
//  AMCServiceCategoriesController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 29/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCServiceCategoriesViewController.h"
#import "ServiceCategory.h"


@interface AMCServiceCategoriesViewController ()
@property (weak) IBOutlet NSMenuItem *addCategoryMenuItem;
@property (weak) IBOutlet NSMenuItem *viewCategoryMenuItem;
@property (weak) IBOutlet NSMenuItem *showNotesMenuItem;

@property (weak) IBOutlet NSMenuItem *rightClickViewCategoryMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickShowNotesMenuItem;

@end

@implementation AMCServiceCategoriesViewController

-(NSString *)nibName {
    return @"AMCServiceCategoriesViewController";
}
#pragma mark - NSMenuDelegate
-(void)menuNeedsUpdate:(NSMenu*)menu {
    menu.autoenablesItems = NO;
    if (menu == self.actionMenu) {
        menu.autoenablesItems = NO;
        self.addCategoryMenuItem.enabled = YES;
        BOOL selectedObjectExists = (self.selectedObject)?YES:NO;
        self.viewCategoryMenuItem.enabled = selectedObjectExists;
        self.showNotesMenuItem.enabled = selectedObjectExists;
    } else if (menu == self.rightClickMenu) {
        menu.autoenablesItems = NO;
        self.rightClickViewCategoryMenuItem.enabled = YES;
        self.rightClickShowNotesMenuItem.enabled = YES;
    }
}
-(void)editObjectViewController:(EditObjectViewController *)controller didCompleteCreationOfObject:(id)object {
    ServiceCategory * serivceCategory = (ServiceCategory*)controller.objectToEdit;
    serivceCategory.lastUpdatedDate = [NSDate date];
    serivceCategory.bqNeedsCoreDataExport = [NSNumber numberWithBool:YES];
    [super editObjectViewController:controller didCompleteCreationOfObject:object];
}
- (void)editObjectViewController:(EditObjectViewController *)controller didEditObject:(id)object {
    ServiceCategory * serivceCategory = (ServiceCategory*)controller.objectToEdit;
    serivceCategory.lastUpdatedDate = [NSDate date];
    serivceCategory.bqNeedsCoreDataExport = [NSNumber numberWithBool:YES];
    [super editObjectViewController:controller didEditObject:object];
}
@end
