//
//  AMCCategoriesRootNode.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCCategoriesRootNode.h"
#import "AMCCashBookNode.h"
#import "AMCServiceCategoriesNode.h"
@interface AMCCategoriesRootNode()
@end

@implementation AMCCategoriesRootNode

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.cashbookNode = [aDecoder decodeObjectForKey:@"cashbookNode"];
        self.servicesNode = [aDecoder decodeObjectForKey:@"servicesNode"];
    }
    return self;
}
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.cashbookNode forKey:@"cashbookNode"];
    [aCoder encodeObject:self.servicesNode forKey:@"servicesNode"];
}
-(instancetype)initWithName:(NSString *)string isLeaf:(BOOL)isLeaf {
    self = [super initWithName:@"All Categories" isLeaf:NO];
    if (self) {
        self.isDeletable = NO;
        self.cashbookNode = [self addChild:[[AMCCashBookNode alloc] init]];
        self.servicesNode = [self addChild:[[AMCServiceCategoriesNode alloc] init]];
    }
    return self;
}

@end
