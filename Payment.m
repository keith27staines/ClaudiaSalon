//
//  Payment.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "Payment.h"
#import "Account.h"
#import "Note.h"
#import "PaymentCategory.h"
#import "RecurringBill.h"
#import "SaleItem.h"
#import "ShoppingList.h"
#import "WorkRecord.h"


@implementation Payment

@dynamic amount;
@dynamic bankStatementTransactionDate;
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
@dynamic reconciledWithBankStatement;
@dynamic sourceAccount;
@dynamic voided;
@dynamic transactionFeeIncoming;
@dynamic account;
@dynamic bonusForWorkRecord;
@dynamic notes;
@dynamic paymentCategory;
@dynamic refunding;
@dynamic shoppingList;
@dynamic workRecord;
@dynamic recurringBill;

@end
