//
//  Customer+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 23/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Customer.h"
#import "AMCSalonDocument.h"
#import "AMCObjectWithNotesProtocol.h"

@interface Customer (Methods) <AMCObjectWithNotesProtocol>
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
-(NSNumber*)totalMoneySpent;
-(NSNumber*)totalMoneyRefunded;
-(NSNumber*)numberOfPreviousVisits;
@end
