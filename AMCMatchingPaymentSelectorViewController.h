//
//  AMCMatchingPaymentSelectorViewController.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 21/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
@class AMCAccountStatementItem;
#import "AMCViewController.h"

@interface AMCMatchingPaymentSelectorViewController : AMCViewController
@property (copy) NSArray * pairingRecords;
@property NSMutableDictionary * transactionDictionary;
@property (readonly) AMCAccountStatementItem * computerRecord;
@end
