//
//  ServiceCategory+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "ServiceCategory.h"
#import "AMCSalonDocument.h"
#import "AMCObjectWithNotesProtocol.h"
#import "AMCTreeNode.h"

@interface ServiceCategory (Methods) <AMCObjectWithNotesProtocol, AMCTreeNode>
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
-(BOOL)isHairCategory;
@end
