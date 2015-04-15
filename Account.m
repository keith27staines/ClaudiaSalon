//
//  Account.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 15/04/2015.
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
@dynamic friendlyName;
@dynamic sortCode;
@dynamic csvHeaderLines;
@dynamic csvDateColumn;
@dynamic csvNoteColumn;
@dynamic csvAmountColumn;
@dynamic cardPaymentAccountForSalon;
@dynamic payments;
@dynamic primaryBankAccountForSalon;
@dynamic reconciliations;
@dynamic sales;
@dynamic tillAccountForSalon;

@end
