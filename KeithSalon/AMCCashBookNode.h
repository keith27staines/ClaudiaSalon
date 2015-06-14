//
//  AMCCashBookNode.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

@class Salon,AccountingPaymentGroup,PaymentCategory;

#import "AMCTreeNode.h"

@interface AMCCashBookNode : AMCTreeNode
-(instancetype)initWithAccountancyGroup:(AccountingPaymentGroup*)group;
-(instancetype)initWithPaymentCategory:(PaymentCategory*)category;
@property (readonly) PaymentCategory * paymentCategory;
@end
