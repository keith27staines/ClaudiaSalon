//
//  AMCPermissionDeniedViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCPermissionDeniedViewController.h"

@interface AMCPermissionDeniedViewController ()

@end

@implementation AMCPermissionDeniedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

-(void)dismissController:(id)sender {
    SEL cancelButton = NSSelectorFromString(@"cancelButton:");
    if ([self.callingViewController respondsToSelector:cancelButton]) {
        [self.callingViewController performSelectorOnMainThread:cancelButton withObject:nil waitUntilDone:YES];
    }
    [self.callingViewController dismissController:self];
}

@end
