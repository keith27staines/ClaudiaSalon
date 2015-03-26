//
//  PaymentCategory.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Payment;

@interface PaymentCategory : NSManagedObject

@property (nonatomic, retain) NSString * categoryName;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * fullDescription;
@property (nonatomic, retain) NSNumber * isDefault;
@property (nonatomic, retain) NSNumber * isDirectorsLoan;
@property (nonatomic, retain) NSNumber * isManagersBudgetItem;
@property (nonatomic, retain) NSNumber * isSalary;
@property (nonatomic, retain) NSNumber * isSale;
@property (nonatomic, retain) NSNumber * isStartupCost;
@property (nonatomic, retain) NSNumber * isTransferBetweenAccounts;
@property (nonatomic, retain) NSSet *payments;
@end

@interface PaymentCategory (CoreDataGeneratedAccessors)

- (void)addPaymentsObject:(Payment *)value;
- (void)removePaymentsObject:(Payment *)value;
- (void)addPayments:(NSSet *)values;
- (void)removePayments:(NSSet *)values;

@end
