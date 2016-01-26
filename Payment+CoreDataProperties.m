//
//  Payment+CoreDataProperties.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Payment+CoreDataProperties.h"

@implementation Payment (CoreDataProperties)

@dynamic amount;
@dynamic amountNet;
@dynamic createdDate;
@dynamic direction;
@dynamic hidden;
@dynamic isManagersBudgetItem;
@dynamic isManagersBudgetStatusManuallyChanged;
@dynamic lastUpdatedDate;
@dynamic payeeName;
@dynamic payeeUID;
@dynamic paymentDate;
@dynamic reason;
@dynamic sourceAccount;
@dynamic transactionFee;
@dynamic voided;
@dynamic account;
@dynamic bonusForWorkRecord;
@dynamic notes;
@dynamic paymentCategory;
@dynamic refunding;
@dynamic sale;
@dynamic saleAdvancePayment;
@dynamic shoppingList;
@dynamic templateForRecurringItem;
@dynamic transferPartner;
@dynamic workRecord;

@end
