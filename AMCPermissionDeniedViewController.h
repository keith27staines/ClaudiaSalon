//
//  AMCPermissionDeniedViewController.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

@class AMCSalonDocument,BusinessFunction,Employee, AMCViewController;

#import <Cocoa/Cocoa.h>

@interface AMCPermissionDeniedViewController : NSViewController
@property (weak) AMCViewController * callingViewController;
@property Employee * currentUser;
@property (weak) BusinessFunction * businessFunction;
@property (copy) NSString * editModeVerb;
@property (weak) AMCSalonDocument * salonDocument;
@end
