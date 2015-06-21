//
//  AMCPasswordEditor.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
@class Employee;

#import "AMCViewController.h"

@interface AMCPasswordEditor : AMCViewController

@property (copy) NSString * oldPassword;
@property (copy) NSString * password;
@property Employee * employee;
@property BOOL firstPassword;
@property BOOL resetMode;
@property (weak) IBOutlet NSSecureTextField *passwordField;
@property (weak) IBOutlet NSSecureTextField *previousPasswordField;
@property (weak) IBOutlet NSTextField *titleLabel;

@end
