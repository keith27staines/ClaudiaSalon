//
//  Note+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCSalonDocument.h"
#import "Note.h"

@interface Note (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
@end
