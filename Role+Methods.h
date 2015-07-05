//
//  Role+Methods.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
@class BusinessFunction;
#import "Role.h"

@interface Role (Methods)
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
-(NSNumber*)allowsBusinessFunction:(BusinessFunction*)function verb:(NSString*)verb;
-(Permission*)permissionForBusinessFunction:(BusinessFunction*)function;
@end
