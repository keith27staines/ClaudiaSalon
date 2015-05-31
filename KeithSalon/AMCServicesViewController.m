//
//  AMCServicesViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 29/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCServicesViewController.h"
#import "Service+Methods.h"

@interface AMCServicesViewController ()
@property (weak) IBOutlet NSMenuItem *addServiceMenuItem;
@property (weak) IBOutlet NSMenuItem *viewServiceMenuItem;
@property (weak) IBOutlet NSMenuItem *showNotesMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickViewServiceMenuItem;
@property (weak) IBOutlet NSMenuItem *rightClickShowNotesMenuItem;

@end

@implementation AMCServicesViewController

-(NSString *)nibName {
    return @"AMCServicesViewController";
}
#pragma mark - NSMenuDelegate
-(void)menuNeedsUpdate:(NSMenu*)menu {
    menu.autoenablesItems = NO;
    if (menu == self.actionMenu) {
        menu.autoenablesItems = NO;
        self.addServiceMenuItem.enabled = YES;
        BOOL selectedObjectExists = (self.selectedObject)?YES:NO;
        self.viewServiceMenuItem.enabled = selectedObjectExists;
        self.showNotesMenuItem.enabled = selectedObjectExists;
    } else if (menu == self.rightClickMenu) {
        menu.autoenablesItems = NO;
        self.rightClickViewServiceMenuItem.enabled = YES;
        self.rightClickShowNotesMenuItem.enabled = YES;
    }
}
@end
