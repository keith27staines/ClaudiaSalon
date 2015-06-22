//
//  AMCChangeUserViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 22/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCChangeUserViewController.h"
#import "Employee+Methods.h"

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
@property (weak) IBOutlet NSBox *currentUserBox;
@property (weak) IBOutlet NSLayoutConstraint *verticalGap;

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
- (IBAction)showEnterPassword:(id)sender {
    if (self.currentViewController != self.passwordViewController) {
        self.passwordField.stringValue = @"";
        self.infoLabel.stringValue = @"";
        [self transitionFromViewController:self.currentViewController toViewController:self.passwordViewController options:NSViewControllerTransitionSlideLeft completionHandler:^{
            self.currentViewController = self.passwordViewController;
            [self.view.window makeFirstResponder:self.passwordField];
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
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.usersArrayController.managedObjectContext = salonDocument.managedObjectContext;
    self.passwordField.stringValue = @"";
    self.cancelled = YES;
    self.infoLabel.stringValue = @"";
    [self showSelectUser:self];
    if (salonDocument.currentUser) {
        self.titleLabel.stringValue = @"Switch to another user";
        self.currentUserBox.hidden = NO;
    } else {
        self.titleLabel.stringValue = @"Select user and login";
        self.currentUserBox.hidden = YES;
        self.verticalGap.constant = 50;
    }
    [self.view setNeedsUpdateConstraints:YES];
    [self.view setNeedsLayout:YES];
    [self.view setNeedsDisplay:YES];
    [self.view invalidateIntrinsicContentSize];
    self.employeeTable.doubleAction = @selector(showEnterPassword:);
    self.usersArrayController.filterPredicate = [NSPredicate predicateWithFormat:@"isActive = YES AND self != %@",self.salonDocument.currentUser];
    [self.employeeTable deselectAll:self];
    [self.view.window makeFirstResponder:self.employeeTable];
    [self.view.window layoutIfNeeded];
}
-(void)updateViewConstraints {
    [super updateViewConstraints];
    if (self.salonDocument.currentUser) {
        self.verticalGap.constant = 150;
    } else {
        self.verticalGap.constant = 50;
    }
}
-(Employee *)selectedEmployee {
    return self.usersArrayController.selectedObjects.firstObject;
}
-(void)setSelectedEmployee:(Employee *)employee {
    if (!employee) {
        return;
    }
    [self.employeeTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[self.usersArrayController.arrangedObjects indexOfObject:employee]] byExtendingSelection:NO];
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification {
    self.selectedEmployee = (Employee*)self.usersArrayController.selectedObjects.firstObject;
}
@end
