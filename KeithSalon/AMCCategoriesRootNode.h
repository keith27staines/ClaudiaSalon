//
//  AMCCategoriesRootNode.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCTreeNode.h"

@interface AMCCategoriesRootNode : AMCTreeNode
@property id<AMCTreeNode> cashbookNode;
@property id<AMCTreeNode> servicesNode;
@end
