//
//  PaymentCategory.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 10/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AccountingPaymentGroup, Payment, Salon;

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
@property (nonatomic, retain) Salon *defaultCategoryForMoneyTransfers;
@property (nonatomic, retain) Salon *defaultCategoryForPayments;
@property (nonatomic, retain) Salon *defaultCategoryForSales;
@property (nonatomic, retain) Salon *defaultCategoryForWages;
@property (nonatomic, retain) NSSet *payments;
@property (nonatomic, retain) AccountingPaymentGroup *expenditureAccountingGroup;
@property (nonatomic, retain) AccountingPaymentGroup *incomeAccountingGroup;
@end

@interface PaymentCategory (CoreDataGeneratedAccessors)

- (void)addPaymentsObject:(Payment *)value;
- (void)removePaymentsObject:(Payment *)value;
- (void)addPayments:(NSSet *)values;
- (void)removePayments:(NSSet *)values;

@end
