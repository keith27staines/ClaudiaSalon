//
//  AMCCashBookNode.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//


#import "AMCTreeNode.h"
#import "AMCSystemTreeNode.h"

@interface AMCCashBookNode : AMCSystemTreeNode
@property (readonly) AMCTreeNode * incomeNode;
@property (readonly) AMCTreeNode * expenditureNode;
@end
