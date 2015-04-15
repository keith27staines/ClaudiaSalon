//
//  AMCBankStatementReconciliationViewController.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 06/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
@class Account;
#import "AMCViewController.h"

@interface AMCBankStatementReconciliationViewController : AMCViewController

@property Account * account;
@property NSMutableArray * computerRecords;
@end
