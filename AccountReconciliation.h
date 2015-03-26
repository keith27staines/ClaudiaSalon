//
//  AccountReconciliation.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account;

@interface AccountReconciliation : NSManagedObject

@property (nonatomic, retain) NSNumber * actualBalance;
@property (nonatomic, retain) NSDate * reconciliationDate;
@property (nonatomic, retain) Account *account;

@end
