//
//  Service+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Service.h"
#import "AMCSalonDocument.h"
#import "AMCObjectWithNotesProtocol.h"
#import "AMCTreeNode.h"

@interface Service (Methods) <AMCObjectWithNotesProtocol,AMCTreeNode>
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;

-(NSString*)displayText;

// "" (for not applicable), short, medium, long
@property (copy,readonly) NSString * hairLengthDescription;
@property (copy,readonly) NSString * deluxeDescription;
@end
