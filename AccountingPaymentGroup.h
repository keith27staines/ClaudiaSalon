//
//  AccountingPaymentGroup.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 10/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AccountingPaymentGroup, PaymentCategory, Salon;

@interface AccountingPaymentGroup : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * isExpenditure;
@property (nonatomic, retain) NSNumber * isIncome;
@property (nonatomic, retain) NSNumber * isSystemCategory;
@property (nonatomic, retain) AccountingPaymentGroup *parent;
@property (nonatomic, retain) NSSet *subgroups;
@property (nonatomic, retain) NSSet *expenditurePaymentCategories;
@property (nonatomic, retain) NSSet *incomePaymentCategories;
@property (nonatomic, retain) Salon *salon;
@end

@interface AccountingPaymentGroup (CoreDataGeneratedAccessors)

- (void)addSubgroupsObject:(AccountingPaymentGroup *)value;
- (void)removeSubgroupsObject:(AccountingPaymentGroup *)value;
- (void)addSubgroups:(NSSet *)values;
- (void)removeSubgroups:(NSSet *)values;

- (void)addExpenditurePaymentCategoriesObject:(PaymentCategory *)value;
- (void)removeExpenditurePaymentCategoriesObject:(PaymentCategory *)value;
- (void)addExpenditurePaymentCategories:(NSSet *)values;
- (void)removeExpenditurePaymentCategories:(NSSet *)values;

- (void)addIncomePaymentCategoriesObject:(PaymentCategory *)value;
- (void)removeIncomePaymentCategoriesObject:(PaymentCategory *)value;
- (void)addIncomePaymentCategories:(NSSet *)values;
- (void)removeIncomePaymentCategories:(NSSet *)values;

@end
