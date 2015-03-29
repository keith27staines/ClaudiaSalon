//
//  RecurringBill.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account, Payment, PaymentCategory;

@interface RecurringBill : NSManagedObject

@property (nonatomic, retain) NSNumber * amount;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * direction;
@property (nonatomic, retain) NSDate * firstPaymentDate;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSDate * nextPaymentDate;
@property (nonatomic, retain) NSString * otherParty;
@property (nonatomic, retain) NSNumber * period;
@property (nonatomic, retain) NSString * detail;
@property (nonatomic, retain) Account *account;
@property (nonatomic, retain) NSSet *payments;
@property (nonatomic, retain) PaymentCategory *paymentCategory;
@end

@interface RecurringBill (CoreDataGeneratedAccessors)

- (void)addPaymentsObject:(Payment *)value;
- (void)removePaymentsObject:(Payment *)value;
- (void)addPayments:(NSSet *)values;
- (void)removePayments:(NSSet *)values;

@end
