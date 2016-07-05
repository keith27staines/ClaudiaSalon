//
//  PaymentCategory+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 04/07/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "PaymentCategory.h"

NS_ASSUME_NONNULL_BEGIN

@interface PaymentCategory (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *bqCloudID;
@property (nullable, nonatomic, retain) NSNumber *bqHasClientChanges;
@property (nullable, nonatomic, retain) NSData *bqMetadata;
@property (nullable, nonatomic, retain) NSNumber *bqNeedsCoreDataExport;
@property (nullable, nonatomic, retain) NSString *categoryName;
@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSString *fullDescription;
@property (nullable, nonatomic, retain) NSNumber *isActive;
@property (nullable, nonatomic, retain) NSNumber *isDefault;
@property (nullable, nonatomic, retain) NSNumber *isDirectorsLoan;
@property (nullable, nonatomic, retain) NSNumber *isManagersBudgetItem;
@property (nullable, nonatomic, retain) NSNumber *isSalary;
@property (nullable, nonatomic, retain) NSNumber *isSale;
@property (nullable, nonatomic, retain) NSNumber *isStartupCost;
@property (nullable, nonatomic, retain) NSNumber *isTransferBetweenAccounts;
@property (nullable, nonatomic, retain) NSDate *lastUpdatedDate;
@property (nullable, nonatomic, retain) Salon *defaultCategoryForMoneyTransfers;
@property (nullable, nonatomic, retain) Salon *defaultCategoryForPayments;
@property (nullable, nonatomic, retain) Salon *defaultCategoryForSales;
@property (nullable, nonatomic, retain) Salon *defaultCategoryForWages;
@property (nullable, nonatomic, retain) AccountingPaymentGroup *expenditureAccountingGroup;
@property (nullable, nonatomic, retain) AccountingPaymentGroup *incomeAccountingGroup;
@property (nullable, nonatomic, retain) NSSet<Payment *> *payments;

@end

@interface PaymentCategory (CoreDataGeneratedAccessors)

- (void)addPaymentsObject:(Payment *)value;
- (void)removePaymentsObject:(Payment *)value;
- (void)addPayments:(NSSet<Payment *> *)values;
- (void)removePayments:(NSSet<Payment *> *)values;

@end

NS_ASSUME_NONNULL_END
