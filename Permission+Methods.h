//
//  Permission+Methods.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 27/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "Permission.h"

@interface Permission (Methods)
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(Permission*)fetchPermissionWithRole:(Role*)role businessFunction:(BusinessFunction*)businessFunction;
@end
