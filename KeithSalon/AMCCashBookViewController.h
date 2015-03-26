//
//  AMCCashBookViewController.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 18/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

@class Account;
#import "AMCViewController.h"

@interface AMCCashBookViewController : AMCViewController
@property Account * account;
@property (copy) NSArray * statementItems;
@property (copy) NSDate * firstDay;
@property (copy) NSDate * lastDay;
@property double balanceBroughtForward;
@property double balancePerBank;
@end
