//
//  AMCRequestPasswordViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 08/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCRequestPasswordWindowController : NSWindowController
@property (weak) IBOutlet NSSecureTextField *passwordField;
@property NSString * state;
@property (weak) IBOutlet NSTextField *invalidPasswordLabel;
@property (weak) NSWindow * callingWindow;
@end
