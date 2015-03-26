//
//  AMCWelcomeScreen.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/02/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCWelcomeScreen.h"
#import "AppDelegate.h"

@interface AMCWelcomeScreen ()

@end

@implementation AMCWelcomeScreen

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [self.window center];
}
-(NSString *)windowNibName {
    return @"AMCWelcomeScreen";
}
-(void)dismissController:(id)sender {
    [self close];
}

-(IBAction)openDefaultSalon:(id)sender {
    [self.appDelegate openDefaultSalon:sender];
}
@end
