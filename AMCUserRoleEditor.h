//
//  AMCUserRoleEditor.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
@class Employee;

#import "AMCViewController.h"
#import "AMCSalonDocument.h"
@interface AMCUserRoleEditor : AMCViewController
@property (weak) Employee * employee;
@property EditMode editMode;
@end
