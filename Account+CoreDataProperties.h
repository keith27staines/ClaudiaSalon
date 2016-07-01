//
//  Account+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 30/06/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Account.h"

NS_ASSUME_NONNULL_BEGIN

@interface Account (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *accountNumber;
@property (nullable, nonatomic, retain) NSString *bankName;
@property (nullable, nonatomic, retain) NSString *bqCloudID;
@property (nullable, nonatomic, retain) NSNumber *bqHasClientChanges;
@property (nullable, nonatomic, retain) NSData *bqMetadata;
@property (nullable, nonatomic, retain) NSNumber *bqNeedsCoreDataExport;
@property (nullable, nonatomic, retain) NSNumber *csvAmountColumn;
@property (nullable, nonatomic, retain) NSNumber *csvDateColumn;
@property (nullable, nonatomic, retain) NSNumber *csvFeeColumn;
@property (nullable, nonatomic, retain) NSNumber *csvHeaderLines;
@property (nullable, nonatomic, retain) NSNumber *csvNetAmountColumn;
@property (nullable, nonatomic, retain) NSNumber *csvNoteColumn;
@property (nullable, nonatomic, retain) NSNumber *csvStatusColumn;
@property (nullable, nonatomic, retain) NSString *csvStatusExclude;
@property (nullable, nonatomic, retain) NSString *csvStatusInclude;
@property (nullable, nonatomic, retain) NSString *friendlyName;
@property (nullable, nonatomic, retain) NSNumber *isActive;
@property (nullable, nonatomic, retain) NSDate *lastUpdatedDate;
@property (nullable, nonatomic, retain) NSString *sortCode;
@property (nullable, nonatomic, retain) NSNumber *transactionFeePercentageIncoming;
@property (nullable, nonatomic, retain) NSNumber *transactionFeePercentageOutgoing;
@property (nullable, nonatomic, retain) Salon *cardPaymentAccountForSalon;
@property (nullable, nonatomic, retain) NSSet<Payment *> *payments;
@property (nullable, nonatomic, retain) Salon *primaryBankAccountForSalon;
@property (nullable, nonatomic, retain) NSSet<AccountReconciliation *> *reconciliations;
@property (nullable, nonatomic, retain) NSSet<Sale *> *sales;
@property (nullable, nonatomic, retain) Salon *tillAccountForSalon;

@end

@interface Account (CoreDataGeneratedAccessors)

- (void)addPaymentsObject:(Payment *)value;
- (void)removePaymentsObject:(Payment *)value;
- (void)addPayments:(NSSet<Payment *> *)values;
- (void)removePayments:(NSSet<Payment *> *)values;

- (void)addReconciliationsObject:(AccountReconciliation *)value;
- (void)removeReconciliationsObject:(AccountReconciliation *)value;
- (void)addReconciliations:(NSSet<AccountReconciliation *> *)values;
- (void)removeReconciliations:(NSSet<AccountReconciliation *> *)values;

- (void)addSalesObject:(Sale *)value;
- (void)removeSalesObject:(Sale *)value;
- (void)addSales:(NSSet<Sale *> *)values;
- (void)removeSales:(NSSet<Sale *> *)values;

@end

NS_ASSUME_NONNULL_END
