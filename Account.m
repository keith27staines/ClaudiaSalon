//
//  Account.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 20/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "Account.h"
#import "AccountReconciliation.h"
#import "Payment.h"
#import "Sale.h"
#import "Salon.h"


@implementation Account

@dynamic accountNumber;
@dynamic bankName;
@dynamic csvAmountColumn;
@dynamic csvDateColumn;
@dynamic csvHeaderLines;
@dynamic csvNoteColumn;
@dynamic friendlyName;
@dynamic sortCode;
@dynamic csvFeeColumn;
@dynamic csvNetAmountColumn;
@dynamic csvStatusColumn;
@dynamic csvStatusInclude;
@dynamic csvStatusExclude;
@dynamic cardPaymentAccountForSalon;
@dynamic payments;
@dynamic primaryBankAccountForSalon;
@dynamic reconciliations;
@dynamic sales;
@dynamic tillAccountForSalon;

@end
