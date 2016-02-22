//
//  AMCChangeUserViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 22/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCChangeUserViewController.h"
#import "Employee.h"
#import "AMCSalonDocument.h"

@interface AMCChangeUserViewController () <NSTableViewDelegate>
@property (strong) IBOutlet NSArrayController *usersArrayController;
@property (weak) IBOutlet NSTextField *infoLabel;

@property (weak) IBOutlet NSButton *okButton;
@property (weak) IBOutlet NSSecureTextField *passwordField;
@property (strong) IBOutlet NSViewController *selectUserViewController;
@property (strong) IBOutlet NSViewController *passwordViewController;
@property (weak) NSViewController * currentViewController;
@property (weak) IBOutlet NSView *containerView;
@property (weak) Employee * selectedEmployee;
@property (weak) IBOutlet NSTableView *employeeTable;
@property (weak) IBOutlet NSTextField *titleLabel;

@end

@implementation AMCChangeUserViewController

-(NSString *)nibName {
    return @"AMCChangeUserViewController";
}
-(void)viewDidLoad {
    [self addChildViewController:self.selectUserViewController];
    [self addChildViewController:self.passwordViewController];
    [self.containerView addSubview:self.selectUserViewController.view];
    self.currentViewController = self.selectUserViewController;
}
-(NSString *)switchUserTitle{
    if (self.authorizingMode) return @"Select Authorizing Manager";

    if (self.salonDocument.currentUser) {
        return @"Switch User or Sign-out";
    } else {
        return @"Select User to Sign-in";
    }
}
-(void)displayCurrentUserBox:(BOOL)displayCurrentUserBox {
    if (self.authorizingMode) {
        self.currentUserBox.hidden = YES;
        self.verticalGap.animator.constant = 50;
        return;
    }
    if (displayCurrentUserBox == YES) {
        self.verticalGap.animator.constant = 150;
        self.currentUserBox.hidden = NO;
    } else {
        self.currentUserBox.hidden = YES;
        self.verticalGap.animator.constant = 50;
    }
}
- (IBAction)showEnterPassword:(id)sender {
    NSInteger row = [self.employeeTable rowForView:sender];
    if (row < 0 || row == NSNotFound) {
        return;
    }
    [self.employeeTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.employeeTable.selectedRow;
    if (row < 0 || row == NSNotFound) {
        return;
    }
    self.selectedEmployee = self.usersArrayController.arrangedObjects[row];
    [self showGetSelectedUsersPassword];
}

-(void)showGetSelectedUsersPassword {
    if (self.currentViewController != self.passwordViewController) {
        self.titleLabel.stringValue = @"Enter Password";
        self.passwordField.stringValue = @"";
        self.infoLabel.stringValue = @"";
        [self transitionFromViewController:self.currentViewController toViewController:self.passwordViewController options:NSViewControllerTransitionSlideLeft completionHandler:^{
            self.currentViewController = self.passwordViewController;
            [self.view.window makeFirstResponder:self.passwordField];
            [self displayCurrentUserBox:NO];
        }];
    }
}
- (IBAction)showSelectUser:(id)sender {
    if (self.currentViewController != self.selectUserViewController) {
        [self transitionFromViewController:self.currentViewController toViewController:self.selectUserViewController options:NSViewControllerTransitionSlideRight completionHandler:^{
            self.currentViewController = self.selectUserViewController;
            [self.view.window makeFirstResponder:self.employeeTable];
        }];
    }
    self.titleLabel.stringValue = self.switchUserTitle;
    if (self.salonDocument.currentUser && !self.authorizingMode) {
        [self displayCurrentUserBox:YES];
    } else {
        [self displayCurrentUserBox:NO];
    }
}
- (IBAction)trySwitchToUser:(id)sender {
    if ([self.passwordField.stringValue isEqualToString:self.selectedEmployee.password]) {
        self.cancelled = NO;
        self.salonDocument.currentUser = self.selectedEmployee;
        self.infoLabel.stringValue = @"";
        [self dismissController:self];
    } else {
        self.infoLabel.stringValue = @"Invalid Password!";
    }
}
- (IBAction)signout:(id)sender {
    self.salonDocument.currentUser = nil;
    [self displayCurrentUserBox:NO];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.usersArrayController.managedObjectContext = salonDocument.managedObjectContext;
    self.passwordField.stringValue = @"";
    self.cancelled = YES;
    self.infoLabel.stringValue = @"";
    self.currentUserBox.hidden = YES;
    self.verticalGap.constant = 50;
    [self showSelectUser:self];
    [self.view invalidateIntrinsicContentSize];
    [self.view layout];
    [self.view setNeedsDisplay:YES];
    self.employeeTable.doubleAction = @selector(showEnterPassword:);
    NSPredicate * predicate = nil;
    if (self.authorizingMode) {
       predicate = [NSPredicate predicateWithFormat:@"any roles = %@",self.salonDocument.salon.managerRole];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"isActive = YES AND self != %@",self.salonDocument.currentUser];
    }
    self.usersArrayController.filterPredicate = predicate;
    [self.employeeTable deselectAll:self];
    [self.employeeTable reloadData];
    [self.view.window makeFirstResponder:self.employeeTable];
    self.selectedEmployee = nil;
}
@end
