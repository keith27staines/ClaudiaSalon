//
//  BusinessFunction+Methods.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "BusinessFunction.h"

@interface BusinessFunction (Methods)
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(BusinessFunction*)fetchBusinessFunctionWithCodeUnitName:(NSString*)name inMoc:(NSManagedObjectContext*)moc;
-(NSArray*)mappedRoles;
@end
