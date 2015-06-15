//
//  AMCCashBookNode.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCCashBookNode.h"
#import "PaymentCategory+Methods.h"
#import "AccountingPaymentGroup+Methods.h"

@interface AMCCashBookNode()
@property PaymentCategory * paymentCategory;
@end

@implementation AMCCashBookNode

-(instancetype)initWithRepresentedObject:(id<AMCTreeNode>)representedObject {
    self = [super initWithRepresentedObject:representedObject loadSubnodes:NO loadLeaves:NO];
    return self;
}
-(instancetype)initWithAccountancyGroup:(AccountingPaymentGroup*)group {
    self = [self initWithRepresentedObject:group];
    NSMutableArray * sortDescriptors = nil;
    NSArray * sortedArray = nil;
    if (self) {
        sortDescriptors = [NSMutableArray array];
        [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"isSystemCategory" ascending:NO]];
        [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
        [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"isLeaf" ascending:YES]];
        sortedArray = [[group.subgroups allObjects] sortedArrayUsingDescriptors:sortDescriptors];
        for (AccountingPaymentGroup * subgroup in sortedArray) {
            [self addChild:[[AMCCashBookNode alloc] initWithAccountancyGroup:subgroup] updateRepresentedObject:NO];
        }
        if (group.isExpenditure.boolValue) {
            sortDescriptors = [NSMutableArray array];
            [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"categoryName" ascending:YES]];
            sortedArray = [[group.expenditurePaymentCategories allObjects] sortedArrayUsingDescriptors:sortDescriptors];
            for (PaymentCategory * expenditureCategory in sortedArray) {
                [self addChild:[[AMCCashBookNode alloc] initWithPaymentCategory:expenditureCategory] updateRepresentedObject:NO];
            }
        }
        if (group.isIncome.boolValue) {
            sortDescriptors = [NSMutableArray array];
            [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"categoryName" ascending:YES]];
            sortedArray = [[group.incomePaymentCategories allObjects] sortedArrayUsingDescriptors:sortDescriptors];
            for (PaymentCategory * incomeCategory in sortedArray) {
                [self addChild:[[AMCCashBookNode alloc] initWithPaymentCategory:incomeCategory] updateRepresentedObject:NO];
            }
        }
    }
    return self;
}
-(BOOL)isExpenditure {
    if (self.accountingGroup) {
        return self.accountingGroup.isExpenditure.boolValue;
    } else {
        return ((AMCCashBookNode*)(self.parentNode)).isExpenditure;
    }
}
-(BOOL)isIncome {
    if (self.accountingGroup) {
        return self.accountingGroup.isIncome.boolValue;
    } else {
        return ((AMCCashBookNode*)(self.parentNode)).isIncome;
    }
}
-(instancetype)initWithPaymentCategory:(PaymentCategory*)category {
    self = [super initWithName:category.categoryName isLeaf:YES];
    if (self) {
        self.paymentCategory = category;
    }
    return self;
}
-(NSString *)name {
    if (self.paymentCategory) {
        return self.paymentCategory.categoryName;
    } else {
        return [super name];
    }
}
-(void)setName:(NSString *)name {
    if (self.paymentCategory) {
        self.paymentCategory.categoryName = name;
    } else {
        [super setName:name];
    }
}
-(AMCTreeNode*)addChild:(AMCTreeNode*)child {
    AMCCashBookNode * accountancyNode = (AMCCashBookNode*)child;
    child = [super addChild:child];
    if (child && child.isLeaf) {
        if (self.accountingGroup.isExpenditure.boolValue) {
            [self.accountingGroup addExpenditurePaymentCategoriesObject:accountancyNode.paymentCategory];
        } else {
            [self.accountingGroup addIncomePaymentCategoriesObject:accountancyNode.paymentCategory];
        }
    }
    return child;
}
-(AMCTreeNode*)removeChild:(AMCTreeNode*)child {
    AMCCashBookNode * accountancyNode = (AMCCashBookNode*)child;
    child = [super removeChild:child];
    if (child.isLeaf) {
        if (self.accountingGroup.isExpenditure.boolValue) {
            [self.accountingGroup removeExpenditurePaymentCategoriesObject:accountancyNode.paymentCategory];
        } else {
            [self.accountingGroup removeIncomePaymentCategoriesObject:accountancyNode.paymentCategory];
        }
    } else {
        [self.accountingGroup removeSubgroupsObject:child.representedObject];
    }
    return child;
}
-(AccountingPaymentGroup*)accountingGroup {
    return (AccountingPaymentGroup*)self.representedObject;
}
@end
