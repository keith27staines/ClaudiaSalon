//
//  AMCEmployeesViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 29/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCEmployeesViewController.h"

@interface AMCEmployeesViewController ()

@end

@implementation AMCEmployeesViewController

-(NSString *)nibName {
    return @"AMCEmployeesViewController";
}
-(NSArray *)initialSortDescriptors {
    return @[[NSSortDescriptor sortDescriptorWithKey:@"isActive" ascending:NO],[NSSortDescriptor sortDescriptorWithKey:@"fullName" ascending:YES selector:@selector(caseInsensitiveCompare:)]];
}

@end
