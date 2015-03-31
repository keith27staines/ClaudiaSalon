//
//  AccountReconciliation.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account;

@interface AccountReconciliation : NSManagedObject

@property (nonatomic, retain) NSNumber * actualBalance;
@property (nonatomic, retain) NSDate * reconciliationDate;
@property (nonatomic, retain) Account *account;

@end
