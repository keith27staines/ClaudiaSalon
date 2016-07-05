//
//  AccountingPaymentGroup+Methods.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 10/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AccountingPaymentGroup+Methods.h"
#import "Salon.h"
#import "PaymentCategory.h"

@implementation AccountingPaymentGroup (Methods)
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AccountingPaymentGroup" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    
    // Specify how the fetched objects should be sorted
    [fetchRequest setSortDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]]];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"Unexpected error: %@",error);
    }
    return fetchedObjects;
}
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc
{
    AccountingPaymentGroup * group = [NSEntityDescription insertNewObjectForEntityForName:@"AccountingPaymentGroup" inManagedObjectContext:moc];
    return group;
}
+(void)buildDefaultGroupsForSalon:(Salon*)salon {
    if (!salon.rootAccountingGroup) {
        AccountingPaymentGroup * root = [AccountingPaymentGroup createObjectInMoc:salon.managedObjectContext];
        root.isExpenditure = @YES;
        root.isIncome = @YES;
        root.isSystemCategory = @YES;
        root.name = @"Accounting Categories";
        salon.rootAccountingGroup = root;
        
        AccountingPaymentGroup * income = [AccountingPaymentGroup createObjectInMoc:salon.managedObjectContext];
        income.isExpenditure = @NO;
        income.isIncome = @YES;
        income.isSystemCategory = @YES;
        income.name = @"Income";
        income.parent = root;
        income.incomeRoot = salon;
        
        AccountingPaymentGroup * expenditure = [AccountingPaymentGroup createObjectInMoc:salon.managedObjectContext];
        expenditure.isExpenditure = @YES;
        expenditure.isIncome = @NO;
        expenditure.isSystemCategory = @YES;
        expenditure.name = @"Expenditure";
        expenditure.parent = root;
        expenditure.expenditureRoot = salon;
        
        salon.expenditureOtherGroup = [expenditure addSubgroupWithName:@"Other Expenditure"];
        salon.expenditureOtherGroup.isSystemCategory = @YES;
        
        salon.incomeOtherGroup = [income addSubgroupWithName:@"Other Income"];
        salon.incomeOtherGroup.isSystemCategory = @YES;
        
        for (NSString * name in [AccountingPaymentGroup defaultIncomeGroupNames]) {
            [income addSubgroupWithName:name];
        }
        for (NSString * name in [AccountingPaymentGroup defaultExpenditureGroupNames]) {
            [expenditure addSubgroupWithName:name];
        }
        for (PaymentCategory * category in [PaymentCategory allObjectsWithMoc:salon.managedObjectContext]) {
            category.incomeAccountingGroup = salon.incomeOtherGroup;
            category.expenditureAccountingGroup = salon.expenditureOtherGroup;
        }
    }
}
-(AccountingPaymentGroup*)addSubgroupWithName:(NSString*)name {
    AccountingPaymentGroup * subgroup = [AccountingPaymentGroup createObjectInMoc:self.managedObjectContext];
    subgroup.name = name;
    subgroup.isIncome = self.isIncome;
    subgroup.isExpenditure = self.isExpenditure;
    subgroup.isSystemCategory = @NO;
    subgroup.parent = self;
    return subgroup;
}
+(NSArray*)defaultExpenditureGroupNames {
    return @[@"Accountancy",
             @"Advertising",
             @"Bank charges",
             @"Building and Maintenance",
             @"Cleaning",
             @"Director's Loan (Irina)",
             @"Director's Loan (Keith)",
             @"Drinks",
             @"Equipment",
             @"Garbage",
             @"Insurance",
             @"Phone & Internet",
             @"Refunds",
             @"Rent",
             @"Sales",
             @"Stock",
             @"Sundries",
             @"Transfers",
             @"Travel Expenses",
             @"Wages"];
}
+(NSArray*)defaultIncomeGroupNames {
    return @[@"Sales",
             @"Bank charges",
             @"Director's Loan (Irina)",
             @"Director's Loan (Keith)",
             @"Transfers"];
}

#pragma mark - AMCTreeNodeProtocol
-(AccountingPaymentGroup*)rootNode {
    return self.salon.rootAccountingGroup;
}
-(void)setParentNode:(AccountingPaymentGroup*)parentNode {
    self.parent = parentNode;
}
-(AccountingPaymentGroup*)parentNode {
    return self.parent;
}
-(BOOL)isLeaf {
    return NO;
}
-(BOOL)isSystemNode {
    return self.isSystemCategory.boolValue;
}
-(id<AMCTreeNode>)addChild:(id<AMCTreeNode>)child {
    if ([child isKindOfClass:[AccountingPaymentGroup class]]) {
        AccountingPaymentGroup * group = (AccountingPaymentGroup*)child;
        [self addSubgroupsObject:group];
        return child;
    }
    if ([child isKindOfClass:[PaymentCategory class]]) {
        if (self.isExpenditure.boolValue) {
            [self addExpenditurePaymentCategoriesObject:child];
        } else {
            [self addIncomePaymentCategoriesObject:child];
        }
    }
    return nil;
}
-(id<AMCTreeNode>)removeChild:(id<AMCTreeNode>)child {
    if ([child isKindOfClass:[AccountingPaymentGroup class]]) {
        [self removeSubgroupsObject:child];
        return child;
    }
    if ([child isKindOfClass:[PaymentCategory class]]) {
        if (self.isExpenditure.boolValue) {
            [self removeExpenditurePaymentCategoriesObject:child];
        } else {
            [self removeIncomePaymentCategoriesObject:child];
        }
        return child;
    }
    return nil;
}
-(NSInteger)nodesCount {
    return self.subgroups.count;
}
-(NSInteger)leavesCount {
    return self.expenditurePaymentCategories.count + self.incomePaymentCategories.count;
}
-(NSArray *)leaves {
    if (self.isExpenditure.boolValue) {
        return [[self.expenditurePaymentCategories allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"categoryName" ascending:YES]]];
    } else {
        return [[self.incomePaymentCategories allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"categoryName" ascending:YES]]];
    }
}
-(NSArray *)nodes {
    return [[self.subgroups allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
}

@end
