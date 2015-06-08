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
@property (readonly) id<AMCTreeNode> incomeNode;
@property (readonly) id<AMCTreeNode> expenditureNode;
@end
