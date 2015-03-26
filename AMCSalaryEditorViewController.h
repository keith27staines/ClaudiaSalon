//
//  AMCSalaryEditorViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

@class Employee;
#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCSalaryEditorViewController : AMCViewController

-(void)updateWithEmployee:(Employee*)employee forDate:(NSDate*)date;


@end
