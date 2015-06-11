//
//  AMCCashBookNode.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

@class Salon;

#import "AMCTreeNode.h"

@interface AMCCashBookNode : AMCTreeNode
@property (readonly) AMCTreeNode * incomeNode;
@property (readonly) AMCTreeNode * expenditureNode;
-(instancetype)initWithSalon:(Salon*)salon;
@end
