//
//  AMCSystemTreeNode.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCSystemTreeNode.h"

@implementation AMCSystemTreeNode

-(instancetype)initWithName:(NSString *)string isLeaf:(BOOL)isLeaf {
    self = [super initWithName:string isLeaf:NO];
    if (self) {
        self.isDeletable = NO;
    }
    return self;
}
@end
