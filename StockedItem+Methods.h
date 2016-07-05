//
//  StockedItem+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/12/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
#import "AMCSalonDocument.h"
#import "StockedItem.h"
#import "AMCObjectWithNotesProtocol.h"

@interface StockedItem (Methods) <AMCObjectWithNotesProtocol>
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
-(NSSet*)nonAuditNotes;
@end
