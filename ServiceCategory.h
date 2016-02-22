//
//  ServiceCategory.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ServiceCategory.h"
#import "AMCObjectWithNotesProtocol.h"
#import "AMCTreeNode.h"

@class Note, Salon, Service;

NS_ASSUME_NONNULL_BEGIN


@interface ServiceCategory: NSManagedObject <AMCObjectWithNotesProtocol, AMCTreeNode>
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
-(BOOL)isHairCategory;
@end

NS_ASSUME_NONNULL_END

#import "ServiceCategory+CoreDataProperties.h"
