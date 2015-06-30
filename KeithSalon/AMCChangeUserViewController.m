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
    NSInteger row = [self.employeeTable rowForView:sender];
    if (row < 0 || row == NSNotFound) {
        return;
    }
    self.selectedEmployee = self.usersArrayController.arrangedObjects[row];
    if (self.currentViewController != self.passwordViewController) {
        self.titleLabel.stringValue = @"Enter Password";
        self.passwordField.stringValue = @"";
        self.infoLabel.stringValue = @"";
        [self transitionFromViewController:self.currentViewController toViewController:self.passwordViewController options:NSViewControllerTransitionSlideLeft completionHandler:^{
            self.currentViewController = self.passwordViewController;
            [self.view.window makeFirstResponder:self.passwordField];
            self.verticalGap.animator.constant = 50;
            self.currentUserBox.hidden = YES;
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
    if (self.salonDocument.currentUser) {
        self.titleLabel.stringValue = @"Switch User or Sign-out";
        self.currentUserBox.hidden = NO;
        self.verticalGap.animator.constant = 150;
    } else {
        self.titleLabel.stringValue = @"Select user and Sign-in";
        self.currentUserBox.hidden = YES;
        self.verticalGap.animator.constant = 50;
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
    self.currentUserBox.hidden = YES;
    self.verticalGap.animator.constant = 50;
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.usersArrayController.managedObjectContext = salonDocument.managedObjectContext;
    self.passwordField.stringValue = @"";
    self.cancelled = YES;
    self.infoLabel.stringValue = @"";
    [self showSelectUser:self];

    [self.view setNeedsUpdateConstraints:YES];
    [self.view setNeedsLayout:YES];
    [self.view setNeedsDisplay:YES];
    [self.view invalidateIntrinsicContentSize];
    self.employeeTable.doubleAction = @selector(showEnterPassword:);
    self.usersArrayController.filterPredicate = [NSPredicate predicateWithFormat:@"isActive = YES AND self != %@",self.salonDocument.currentUser];
    [self.employeeTable deselectAll:self];
    [self.view.window makeFirstResponder:self.employeeTable];
    [self.view.window layoutIfNeeded];
    self.selectedEmployee = nil;
}
-(void)updateViewConstraints {
    [super updateViewConstraints];
    if (self.salonDocument.currentUser) {
        self.verticalGap.constant = 150;
    } else {
        self.verticalGap.constant = 50;
    }
}
@end
