//
//  AMCRequestPasswordViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 08/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCRequestPasswordWindowController.h"

@interface AMCRequestPasswordWindowController ()

@end

@implementation AMCRequestPasswordWindowController

-(NSString *)windowNibName {
    return @"AMCRequestPasswordWindowController";
}
-(NSWindow*)window {
    NSWindow * window = [super window];
    [self.invalidPasswordLabel setHidden:YES];
    self.passwordField.stringValue = @"" ;
    return window;
}
- (IBAction)okButtonClicked:(id)sender {
    if ([self.passwordField.stringValue isEqualToString:@"Angelique"]) {
        [self.invalidPasswordLabel setHidden:YES];
        self.state = @"ok";
        [self.callingWindow endSheet:self.window returnCode:NSModalResponseOK];
    } else {
        self.state = @"failed";
        [self.invalidPasswordLabel setHidden:NO];
    }
}
- (IBAction)cancelButtonClicked:(id)sender {
    self.state = @"cancelled";
    [self.callingWindow endSheet:self.window returnCode:NSModalResponseCancel];
}

@end
