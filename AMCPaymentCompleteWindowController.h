//
//  AMCPaymentCompleteWindowController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 06/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@class AMCPaymentCompleteWindowController;

@interface AMCPaymentCompleteWindowController : NSWindowController

@property (weak) IBOutlet NSButton *printReceiptCheckbox;

@property (weak) IBOutlet NSButton *completePaymentButton;

@property (weak) IBOutlet NSButton *cancelPaymentButton;


- (IBAction)cancelPaymentButtonClicked:(id)sender;
- (IBAction)completePaymentButtonClicked:(id)sender;

@property BOOL state;


@end
