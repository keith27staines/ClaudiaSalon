//
//  AMCPermissionDeniedViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCPermissionDeniedViewController.h"
#import "Employee+Methods.h"
#import "BusinessFunction+Methods.h"

@interface AMCPermissionDeniedViewController ()

@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSTextField *userNameLabel;
@property (weak) IBOutlet NSTextField *businessFunctionLabel;
@property (weak) IBOutlet NSTextField *verbLabel;


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
