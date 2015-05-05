//
//  Sale.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 05/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account, Appointment, Customer, Note, Payment, SaleItem;

@interface Sale : NSManagedObject

@property (nonatomic, retain) NSNumber * actualCharge;
@property (nonatomic, retain) NSNumber * amountGivenByCustomer;
@property (nonatomic, retain) NSNumber * changeGiven;
@property (nonatomic, retain) NSNumber * chargeAfterIndividualDiscounts;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * discountAmount;
@property (nonatomic, retain) NSNumber * discountType;
@property (nonatomic, retain) NSNumber * hidden;
@property (nonatomic, retain) NSNumber * isQuote;
@property (nonatomic, retain) NSDate * lastUpdatedDate;
@property (nonatomic, retain) NSNumber * nominalCharge;
@property (nonatomic, retain) NSNumber * voided;
@property (nonatomic, retain) Account *account;
@property (nonatomic, retain) Customer *customer;
@property (nonatomic, retain) Appointment *fromAppointment;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) NSSet *payments;
@property (nonatomic, retain) NSSet *saleItem;
@property (nonatomic, retain) Payment *advancePayment;
@end

@interface Sale (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

- (void)addPaymentsObject:(Payment *)value;
- (void)removePaymentsObject:(Payment *)value;
- (void)addPayments:(NSSet *)values;
- (void)removePayments:(NSSet *)values;

- (void)addSaleItemObject:(SaleItem *)value;
- (void)removeSaleItemObject:(SaleItem *)value;
- (void)addSaleItem:(NSSet *)values;
- (void)removeSaleItem:(NSSet *)values;

@end
