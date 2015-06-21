//
//  AMCPasswordEditor.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCPasswordEditor.h"
#import "Employee+Methods.h"

@interface AMCPasswordEditor () <NSTextFieldDelegate>
@property (weak) IBOutlet NSButton *doneButton;

@end

@implementation AMCPasswordEditor

-(NSString *)nibName {
    return @"AMCPasswordEditor";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.previousPasswordField.stringValue = @"";
    self.passwordField.stringValue = @"";
    self.previousPasswordField.placeholderString = @"Enter Old Password";
    self.passwordField.placeholderString = @"Enter New Password";
    if (self.firstPassword) {
        self.previousPasswordField.enabled = NO;
        self.passwordField.enabled = YES;
        [self.view.window makeFirstResponder:self.passwordField];
        self.titleLabel.stringValue = @"Set Password";
    } else {
        if (self.resetMode) {
            // Admin has to reset user's password
            self.previousPasswordField.enabled = NO;
            self.passwordField.enabled = YES;
            [self.view.window makeFirstResponder:self.passwordField];
            self.titleLabel.stringValue = @"Reset User's Password";
        } else {
            // User changing their own password
            self.previousPasswordField.enabled = YES;
            self.passwordField.enabled = NO;
            [self.view.window makeFirstResponder:self.previousPasswordField];
            self.titleLabel.stringValue = @"Change Your Password";
        }
    }
    self.doneButton.enabled = NO;
}
- (IBAction)doneButton:(id)sender {
    self.employee.password = self.passwordField.stringValue;
    [self dismissController:self];
}

-(void)controlTextDidChange:(NSNotification *)obj {
    self.doneButton.enabled = NO;
    if (obj.object == self.passwordField) {
        self.doneButton.enabled = [self isNewPasswordValid:self.passwordField.stringValue];
    }
}
- (IBAction)previousPasswordEntered:(id)sender {
    if ([self.previousPasswordField.stringValue isEqualToString:self.employee.password]) {
        self.passwordField.enabled = YES;
        [self.view.window makeFirstResponder:self.passwordField];
        self.previousPasswordField.enabled = NO;
    }
}
- (IBAction)newPasswordEntered:(id)sender {
    if ([self isNewPasswordValid:self.passwordField.stringValue]) {
        [self.view.window setDefaultButtonCell:self.doneButton.cell];
    }
}

-(BOOL)isNewPasswordValid:(NSString*)newPassword {
    if (!newPassword) return NO;
    if (newPassword.length < 4) return NO;
    return YES;
}

@end
