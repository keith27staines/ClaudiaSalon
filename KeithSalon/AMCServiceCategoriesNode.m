//
//  AMCServiceCategoriesNode.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCServiceCategoriesNode.h"
#import "ServiceCategory+Methods.h"

@interface AMCServiceCategoriesNode()
{
    
}
@property AMCSystemTreeNode * hairNode;
@property AMCSystemTreeNode * beautyNode;
@property AMCSystemTreeNode * otherNode;
@end

@implementation AMCServiceCategoriesNode

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.hairNode = [aDecoder decodeObjectForKey:@"hairNode"];
        self.beautyNode = [aDecoder decodeObjectForKey:@"beautyNode"];
        self.otherNode = [aDecoder decodeObjectForKey:@"otherNode"];
    }
    return self;
}
-(void)setMoc:(NSManagedObjectContext *)moc {
    [super setMoc:moc];
    [self mergeUserCategories];
}
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.hairNode forKey:@"hairNode"];
    [aCoder encodeObject:self.beautyNode forKey:@"beautyNode"];
    [aCoder encodeObject:self.otherNode forKey:@"otherNode"];
}

-(instancetype)initWithName:(NSString *)string isLeaf:(BOOL)isLeaf {
    self = [super initWithName:@"Service Categories" isLeaf:isLeaf];
    if (self) {
        self.otherNode = [self addChild:[[AMCSystemTreeNode alloc] initWithName:@"Other" isLeaf:NO]];
        self.defaultChildNode = self.otherNode;
        self.hairNode = [self addChild:[[AMCTreeNode alloc] initWithName:@"Hair" isLeaf:NO]];
        self.hairNode.defaultChildNode = [self.hairNode addChild:[[AMCTreeNode alloc] initWithName:@"Other" isLeaf:NO]];
        self.beautyNode = [self addChild:[[AMCTreeNode alloc] initWithName:@"Beauty" isLeaf:NO]];
        self.beautyNode.defaultChildNode = [self.beautyNode addChild:[[AMCTreeNode alloc] initWithName:@"Other" isLeaf:NO]];
        self.hairNode.isDeletable = NO;
        self.beautyNode.isDeletable = NO;
        self.hairNode.defaultChildNode.isDeletable = NO;
        self.beautyNode.defaultChildNode.isDeletable = NO;
        self.defaultChildNode.isDeletable = NO;
        
        // Add default hair categories
        AMCTreeNode * node = self.hairNode;
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Cutting and washing" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Restyling" isLeaf:NO]];
        
        // Add default beauty categories
        node = self.beautyNode;
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Manicure" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Pedicure" isLeaf:NO]];
        [node addChild:[[AMCTreeNode alloc] initWithName:@"Makeup" isLeaf:NO]];
    }
    return self;
}
-(void)mergeUserCategories {
    NSAssert(self.moc, @"Managed object context must not be nil");
    NSMutableArray * allServiceCategories = [[ServiceCategory allObjectsWithMoc:self.moc] mutableCopy];
    for (ServiceCategory * serviceCategory in allServiceCategories) {
        AMCTreeNode * node = nil;
        if (![self containsLeafWithName:serviceCategory.name]) {
            node = [[AMCTreeNode alloc] initWithName:serviceCategory.name isLeaf:YES];
            [self.defaultChildNode addChild:node];
            node.isDeletable = NO;
        }
    }
}


@end
