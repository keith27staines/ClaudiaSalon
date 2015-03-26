//
//  Payment.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "Payment.h"
#import "Account.h"
#import "Note.h"
#import "PaymentCategory.h"
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
@dynamic account;
@dynamic bonusForWorkRecord;
@dynamic notes;
@dynamic paymentCategory;
@dynamic refunding;
@dynamic shoppingList;
@dynamic workRecord;

@end
