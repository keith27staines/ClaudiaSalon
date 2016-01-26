//
//  AccountingPaymentGroup+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "AccountingPaymentGroup.h"

NS_ASSUME_NONNULL_BEGIN

@interface AccountingPaymentGroup (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *isExpenditure;
@property (nullable, nonatomic, retain) NSNumber *isIncome;
@property (nullable, nonatomic, retain) NSNumber *isSystemCategory;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) Salon *expenditureOther;
@property (nullable, nonatomic, retain) NSSet<PaymentCategory *> *expenditurePaymentCategories;
@property (nullable, nonatomic, retain) Salon *expenditureRoot;
@property (nullable, nonatomic, retain) Salon *incomeOther;
@property (nullable, nonatomic, retain) NSSet<PaymentCategory *> *incomePaymentCategories;
@property (nullable, nonatomic, retain) Salon *incomeRoot;
@property (nullable, nonatomic, retain) AccountingPaymentGroup *parent;
@property (nullable, nonatomic, retain) Salon *salon;
@property (nullable, nonatomic, retain) NSSet<AccountingPaymentGroup *> *subgroups;

@end

@interface AccountingPaymentGroup (CoreDataGeneratedAccessors)

- (void)addExpenditurePaymentCategoriesObject:(PaymentCategory *)value;
- (void)removeExpenditurePaymentCategoriesObject:(PaymentCategory *)value;
- (void)addExpenditurePaymentCategories:(NSSet<PaymentCategory *> *)values;
- (void)removeExpenditurePaymentCategories:(NSSet<PaymentCategory *> *)values;

- (void)addIncomePaymentCategoriesObject:(PaymentCategory *)value;
- (void)removeIncomePaymentCategoriesObject:(PaymentCategory *)value;
- (void)addIncomePaymentCategories:(NSSet<PaymentCategory *> *)values;
- (void)removeIncomePaymentCategories:(NSSet<PaymentCategory *> *)values;

- (void)addSubgroupsObject:(AccountingPaymentGroup *)value;
- (void)removeSubgroupsObject:(AccountingPaymentGroup *)value;
- (void)addSubgroups:(NSSet<AccountingPaymentGroup *> *)values;
- (void)removeSubgroups:(NSSet<AccountingPaymentGroup *> *)values;

@end

NS_ASSUME_NONNULL_END
