//
//  AMCPaymentCompleteWindowController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 06/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCPaymentCompleteWindowController.h"

@interface AMCPaymentCompleteWindowController ()

@end

@implementation AMCPaymentCompleteWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
-(NSString *)windowNibName
{
    return @"AMCPaymentCompleteWindowController";
}
- (IBAction)cancelPaymentButtonClicked:(id)sender {
    [self closeWindowWithStatus:NO];
}

- (IBAction)completePaymentButtonClicked:(id)sender {
    [self closeWindowWithStatus:YES];
}
-(void)closeWindowWithStatus:(BOOL)status
{
    self.state = status;
    [NSApp endSheet:self.window];
    [self.window close];
    [self.delegate paymentCompleteController:self didCompleteWithStatus:status];
}
@end
