//
//  Payment.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/04/2015.
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
@dynamic transactionFeeIncoming;
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

@end
