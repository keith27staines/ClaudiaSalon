//
//  Sale.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account, Appointment, Customer, Note, SaleItem;

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
@property (nonatomic, retain) NSSet *saleItem;
@end

@interface Sale (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

- (void)addSaleItemObject:(SaleItem *)value;
- (void)removeSaleItemObject:(SaleItem *)value;
- (void)addSaleItem:(NSSet *)values;
- (void)removeSaleItem:(NSSet *)values;

@end
