//
//  Payment.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 05/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "Payment.h"
#import "Account.h"
#import "Note.h"
#import "PaymentCategory.h"
#import "RecurringItem.h"
#import "Sale.h"
#import "SaleItem.h"
#import "ShoppingList.h"
#import "WorkRecord.h"


@implementation Payment

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
@dynamic shoppingList;
@dynamic templateForRecurringItem;
@dynamic workRecord;
@dynamic saleAdvancePayment;

@end
