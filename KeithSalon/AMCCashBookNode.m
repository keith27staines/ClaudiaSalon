//
//  AMCCashBookNode.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCCashBookNode.h"
#import "PaymentCategory+Methods.h"
@interface AMCCashBookNode()
@property AMCTreeNode * incomeNode;
@property AMCTreeNode * expenditureNode;
@end

@implementation AMCCashBookNode

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.incomeNode = [aDecoder decodeObjectForKey:@"incomeNode"];
        self.expenditureNode = [aDecoder decodeObjectForKey:@"expenditureNode"];
    }
    return self;
}
-(void)setMoc:(NSManagedObjectContext *)moc {
    [super setMoc:moc];
    [self mergeUserCategories];
}
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.incomeNode forKey:@"incomeNode"];
    [aCoder encodeObject:self.expenditureNode forKey:@"expenditureNode"];
}

-(instancetype)initWithName:(NSString *)string isLeaf:(BOOL)isLeaf {
    self = [super initWithName:@"Cashbook" isLeaf:isLeaf];
    if (self) {
        self.incomeNode = [self addChild:[[AMCTreeNode alloc] initWithName:@"Income" isLeaf:NO]];
        self.incomeNode.defaultChildNode = [self.incomeNode addChild:[[AMCTreeNode alloc] initWithName:@"Other" isLeaf:NO]];
        self.expenditureNode = [self addChild:[[AMCTreeNode alloc] initWithName:@"Expenditure" isLeaf:NO]];
        self.expenditureNode.defaultChildNode = [self.expenditureNode addChild:[[AMCTreeNode alloc] initWithName:@"Other" isLeaf:NO]];
        self.incomeNode.isDeletable = NO;
        self.expenditureNode.isDeletable = NO;
        self.incomeNode.defaultChildNode.isDeletable = NO;
        self.expenditureNode.defaultChildNode.isDeletable = NO;
        
        // Add default expenditure categories
        AMCTreeNode * node = self.expenditureNode;
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Accountancy" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Advertising" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Bank charges" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Building and Maintenance" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Cleaning" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Director's Loan (Irina)" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Director's Loan (Keith)" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Drinks" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Equipment" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Garbage" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Insurance" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Phone & Internet" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Refunds" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Rent" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Sales" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Stock" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Sundries" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Transfers" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Travel Expenses" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Wages" isLeaf:NO]];

        // Add default income categories
        node = self.incomeNode;
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Sales" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Bank charges" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Director's Loan (Irina)" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Director's Loan (Keith)" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Transfers" isLeaf:NO]];
        
    }
    return self;
}
-(void)mergeUserCategories {
    NSAssert(self.moc, @"Managed object context must not be nil");
    NSMutableArray * allAccountancy = [[PaymentCategory allObjectsWithMoc:self.moc] mutableCopy];
    for (PaymentCategory * paymentCategory in allAccountancy) {
        AMCTreeNode * node = [[AMCTreeNode alloc] initWithName:paymentCategory.categoryName isLeaf:YES];
        node.isDeletable = NO;
        if (![self.incomeNode containsLeafWithName:node.name]) {
            // No leaf with the same name as the payment category exists in the tree yet, so we shall add a new appropriately named leaf. The question is, where to put this leaf?
            [[self bestParentForLeaf:node underNode:self.incomeNode] addChild:[node shallowCopy]];
        }
        if (![self.expenditureNode containsLeafWithName:node.name]) {
            // No leaf with the same name as the payment category exists in the tree yet, so we shall add a new appropriately named leaf. The question is, where to put this leaf?
            [[self bestParentForLeaf:node underNode:self.expenditureNode] addChild:[node shallowCopy]];
        }
    }
}
-(AMCTreeNode*)bestParentForLeaf:(AMCTreeNode*)leaf underNode:(AMCTreeNode*)start {
    if ([start containsNodeWithName:leaf.name]) {
        // There is a node with the right name, and this is the best place to put the new leaf
        return [start nodeWithName:leaf.name];
    } else {
        // There is no node with a matching name, so our best bet is to put the new leaf in the nearest upward default node and let the user move it to a more appropriate location
        return [start mostRecentAncestralDefault];
    }
}
@end
