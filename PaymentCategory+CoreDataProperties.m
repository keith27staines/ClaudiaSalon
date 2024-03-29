//
//  PaymentCategory+CoreDataProperties.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "PaymentCategory+CoreDataProperties.h"

@implementation PaymentCategory (CoreDataProperties)

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
@dynamic expenditureAccountingGroup;
@dynamic incomeAccountingGroup;
@dynamic payments;

@end
