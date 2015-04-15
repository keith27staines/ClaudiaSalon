//
//  Account.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 15/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AccountReconciliation, Payment, Sale, Salon;

@interface Account : NSManagedObject

@property (nonatomic, retain) NSString * accountNumber;
@property (nonatomic, retain) NSString * bankName;
@property (nonatomic, retain) NSString * friendlyName;
@property (nonatomic, retain) NSString * sortCode;
@property (nonatomic, retain) NSNumber * csvHeaderLines;
@property (nonatomic, retain) NSNumber * csvDateColumn;
@property (nonatomic, retain) NSNumber * csvNoteColumn;
@property (nonatomic, retain) NSNumber * csvAmountColumn;
@property (nonatomic, retain) Salon *cardPaymentAccountForSalon;
@property (nonatomic, retain) NSSet *payments;
@property (nonatomic, retain) Salon *primaryBankAccountForSalon;
@property (nonatomic, retain) NSSet *reconciliations;
@property (nonatomic, retain) NSSet *sales;
@property (nonatomic, retain) Salon *tillAccountForSalon;
@end

@interface Account (CoreDataGeneratedAccessors)

- (void)addPaymentsObject:(Payment *)value;
- (void)removePaymentsObject:(Payment *)value;
- (void)addPayments:(NSSet *)values;
- (void)removePayments:(NSSet *)values;

- (void)addReconciliationsObject:(AccountReconciliation *)value;
- (void)removeReconciliationsObject:(AccountReconciliation *)value;
- (void)addReconciliations:(NSSet *)values;
- (void)removeReconciliations:(NSSet *)values;

- (void)addSalesObject:(Sale *)value;
- (void)removeSalesObject:(Sale *)value;
- (void)addSales:(NSSet *)values;
- (void)removeSales:(NSSet *)values;

@end
