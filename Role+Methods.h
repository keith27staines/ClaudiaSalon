//
//  Role+Methods.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "Role.h"

@interface Role (Methods)
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
-(NSNumber*)allowsActionWithName:(NSString*)name;
@end
