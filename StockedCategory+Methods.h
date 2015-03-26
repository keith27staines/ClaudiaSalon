//
//  StockCategory+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/12/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
#import "AMCSalonDocument.h"
#import "StockedCategory.h"
#import "AMCObjectWithNotesProtocol.h"

@interface StockedCategory (Methods) <AMCObjectWithNotesProtocol>

+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(StockedCategory*)stockedCategoryWithName:(NSString*)name withMoc:(NSManagedObjectContext*)moc;
-(NSSet*)nonAuditNotes;

@end
