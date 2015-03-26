//
//  Salary+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 08/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//
#import "AMCSalonDocument.h"
#import "Salary.h"

@interface Salary (Methods)
@property NSNumber * weeklyRate;
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
@end