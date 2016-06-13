//
//  Sale+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Sale.h"

NS_ASSUME_NONNULL_BEGIN

@interface Sale (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *actualCharge;
@property (nullable, nonatomic, retain) NSNumber *amountGivenByCustomer;
@property (nullable, nonatomic, retain) NSString *bqCloudID;
@property (nullable, nonatomic, retain) NSNumber *bqHasClientChanges;
@property (nullable, nonatomic, retain) NSData *bqMetadata;
@property (nullable, nonatomic, retain) NSNumber *bqNeedsCoreDataExport;
@property (nullable, nonatomic, retain) NSNumber *changeGiven;
@property (nullable, nonatomic, retain) NSNumber *chargeAfterIndividualDiscounts;
@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSNumber *discountAmount;
@property (nullable, nonatomic, retain) NSNumber *discountType;
@property (nullable, nonatomic, retain) NSNumber *discountValue;
@property (nullable, nonatomic, retain) NSNumber *discountVersion;
@property (nullable, nonatomic, retain) NSNumber *hidden;
@property (nullable, nonatomic, retain) NSNumber *isQuote;
@property (nullable, nonatomic, retain) NSDate *lastUpdatedDate;
@property (nullable, nonatomic, retain) NSNumber *nominalCharge;
@property (nullable, nonatomic, retain) NSNumber *voided;
@property (nullable, nonatomic, retain) Account *account;
@property (nullable, nonatomic, retain) Payment *advancePayment;
@property (nullable, nonatomic, retain) Customer *customer;
@property (nullable, nonatomic, retain) Appointment *fromAppointment;
@property (nullable, nonatomic, retain) NSSet<Note *> *notes;
@property (nullable, nonatomic, retain) NSSet<Payment *> *payments;
@property (nullable, nonatomic, retain) NSSet<SaleItem *> *saleItem;

@end

@interface Sale (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet<Note *> *)values;
- (void)removeNotes:(NSSet<Note *> *)values;

- (void)addPaymentsObject:(Payment *)value;
- (void)removePaymentsObject:(Payment *)value;
- (void)addPayments:(NSSet<Payment *> *)values;
- (void)removePayments:(NSSet<Payment *> *)values;

- (void)addSaleItemObject:(SaleItem *)value;
- (void)removeSaleItemObject:(SaleItem *)value;
- (void)addSaleItem:(NSSet<SaleItem *> *)values;
- (void)removeSaleItem:(NSSet<SaleItem *> *)values;

@end

NS_ASSUME_NONNULL_END
