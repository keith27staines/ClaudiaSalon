//
//  Account+CoreDataProperties.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Account+CoreDataProperties.h"

@implementation Account (CoreDataProperties)

@dynamic accountNumber;
@dynamic bankName;
@dynamic csvAmountColumn;
@dynamic csvDateColumn;
@dynamic csvFeeColumn;
@dynamic csvHeaderLines;
@dynamic csvNetAmountColumn;
@dynamic csvNoteColumn;
@dynamic csvStatusColumn;
@dynamic csvStatusExclude;
@dynamic csvStatusInclude;
@dynamic friendlyName;
@dynamic sortCode;
@dynamic transactionFeePercentageIncoming;
@dynamic transactionFeePercentageOutgoing;
@dynamic cardPaymentAccountForSalon;
@dynamic payments;
@dynamic primaryBankAccountForSalon;
@dynamic reconciliations;
@dynamic sales;
@dynamic tillAccountForSalon;

@end
