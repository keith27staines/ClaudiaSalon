//
//  AccountingPaymentGroup+CoreDataProperties.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "AccountingPaymentGroup+CoreDataProperties.h"

@implementation AccountingPaymentGroup (CoreDataProperties)

@dynamic isExpenditure;
@dynamic isIncome;
@dynamic isSystemCategory;
@dynamic name;
@dynamic expenditureOther;
@dynamic expenditurePaymentCategories;
@dynamic expenditureRoot;
@dynamic incomeOther;
@dynamic incomePaymentCategories;
@dynamic incomeRoot;
@dynamic parent;
@dynamic salon;
@dynamic subgroups;

@end
