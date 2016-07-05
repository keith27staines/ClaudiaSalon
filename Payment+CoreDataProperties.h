//
//  Payment+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 04/07/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Payment.h"

NS_ASSUME_NONNULL_BEGIN

@interface Payment (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *amount;
@property (nullable, nonatomic, retain) NSNumber *amountNet;
@property (nullable, nonatomic, retain) NSString *bqCloudID;
@property (nullable, nonatomic, retain) NSNumber *bqHasClientChanges;
@property (nullable, nonatomic, retain) NSData *bqMetadata;
@property (nullable, nonatomic, retain) NSNumber *bqNeedsCoreDataExport;
@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSString *direction;
@property (nullable, nonatomic, retain) NSNumber *hidden;
@property (nullable, nonatomic, retain) NSNumber *isActive;
@property (nullable, nonatomic, retain) NSNumber *isManagersBudgetItem;
@property (nullable, nonatomic, retain) NSNumber *isManagersBudgetStatusManuallyChanged;
@property (nullable, nonatomic, retain) NSDate *lastUpdatedDate;
@property (nullable, nonatomic, retain) NSString *payeeName;
@property (nullable, nonatomic, retain) NSString *payeeUID;
@property (nullable, nonatomic, retain) NSDate *paymentDate;
@property (nullable, nonatomic, retain) NSString *reason;
@property (nullable, nonatomic, retain) NSString *sourceAccount;
@property (nullable, nonatomic, retain) NSNumber *transactionFee;
@property (nullable, nonatomic, retain) NSNumber *voided;
@property (nullable, nonatomic, retain) Account *account;
@property (nullable, nonatomic, retain) WorkRecord *bonusForWorkRecord;
@property (nullable, nonatomic, retain) NSSet<Note *> *notes;
@property (nullable, nonatomic, retain) PaymentCategory *paymentCategory;
@property (nullable, nonatomic, retain) SaleItem *refunding;
@property (nullable, nonatomic, retain) Sale *sale;
@property (nullable, nonatomic, retain) Sale *saleAdvancePayment;
@property (nullable, nonatomic, retain) ShoppingList *shoppingList;
@property (nullable, nonatomic, retain) RecurringItem *templateForRecurringItem;
@property (nullable, nonatomic, retain) Payment *transferPartner;
@property (nullable, nonatomic, retain) WorkRecord *workRecord;

@end

@interface Payment (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;

@end

NS_ASSUME_NONNULL_END
