//
//  PaymentCategory.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 10/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "PaymentCategory.h"
#import "AccountingPaymentGroup.h"
#import "Payment.h"
#import "Salon.h"


@implementation PaymentCategory

@dynamic categoryName;
@dynamic createdDate;
@dynamic fullDescription;
@dynamic isDefault;
@dynamic isDirectorsLoan;
@dynamic isManagersBudgetItem;
@dynamic isSalary;
@dynamic isSale;
@dynamic isStartupCost;
@dynamic isTransferBetweenAccounts;
@dynamic defaultCategoryForMoneyTransfers;
@dynamic defaultCategoryForPayments;
@dynamic defaultCategoryForSales;
@dynamic defaultCategoryForWages;
@dynamic payments;
@dynamic expenditureAccountingGroup;
@dynamic incomeAccountingGroup;

@end
