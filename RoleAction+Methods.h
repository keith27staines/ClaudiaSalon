//
//  RoleAction+Methods.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "RoleAction.h"

@interface RoleAction (Methods)
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(RoleAction*)fetchActionWithName:(NSString*)name inMoc:(NSManagedObjectContext*)moc ;
@end
