//
//  AccountingPaymentGroup+Methods.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 10/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AccountingPaymentGroup.h"
#import "AMCSalonDocument.h"
#import "AMCTreeNode.h"

@interface AccountingPaymentGroup (Methods) <AMCTreeNode>
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc;

// Only call this method to initialise the AccountingPaymentGroup entity for a new Salon
+(void)buildDefaultGroupsForSalon:(Salon*)salon;
@end
