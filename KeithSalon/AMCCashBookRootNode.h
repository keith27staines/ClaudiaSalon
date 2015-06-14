//
//  AMCCashBookRootNode.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 14/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//


#import "AMCCashBookNode.h"

@interface AMCCashBookRootNode : AMCCashBookNode
@property (readonly) Salon * salon;
@property (readonly) AMCCashBookNode * expenditureRoot;
@property (readonly) AMCCashBookNode * incomeRoot;
-(instancetype)initWithSalon:(Salon*)salon;
@end
