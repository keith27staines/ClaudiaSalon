//
//  AMCRolesMappingToScreen.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

@class BusinessFunction,Employee;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
#import "AMCViewController.h"

@interface AMCRolesMappingToScreen : AMCViewController
@property BusinessFunction * mappedBusinessFunction;
@property Employee * currentUser;
@property EditMode editMode;
@end
