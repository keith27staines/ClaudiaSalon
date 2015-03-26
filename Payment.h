//
//  Payment.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account, Note, PaymentCategory, SaleItem, ShoppingList, WorkRecord;

@interface Payment : NSManagedObject

@property (nonatomic, retain) NSNumber * amount;
@property (nonatomic, retain) NSDate * bankStatementTransactionDate;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * direction;
@property (nonatomic, retain) NSNumber * hidden;
@property (nonatomic, retain) NSNumber * isManagersBudgetItem;
@property (nonatomic, retain) NSNumber * isManagersBudgetStatusManuallyChanged;
@property (nonatomic, retain) NSDate * lastUpdatedDate;
@property (nonatomic, retain) NSString * payeeName;
@property (nonatomic, retain) NSString * payeeUID;
@property (nonatomic, retain) NSDate * paymentDate;
@property (nonatomic, retain) NSString * reason;
@property (nonatomic, retain) NSNumber * reconciledWithBankStatement;
@property (nonatomic, retain) NSString * sourceAccount;
@property (nonatomic, retain) NSNumber * voided;
@property (nonatomic, retain) Account *account;
@property (nonatomic, retain) WorkRecord *bonusForWorkRecord;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) PaymentCategory *paymentCategory;
@property (nonatomic, retain) SaleItem *refunding;
@property (nonatomic, retain) ShoppingList *shoppingList;
@property (nonatomic, retain) WorkRecord *workRecord;
@end

@interface Payment (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

@end
