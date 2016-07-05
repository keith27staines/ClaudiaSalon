//
//  Service.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AMCObjectWithNotesProtocol.h"
#import "AMCTreeNode.h"
@class Employee, Note, Product, SaleItem, ServiceCategory;

NS_ASSUME_NONNULL_BEGIN



@interface Service:NSManagedObject <AMCObjectWithNotesProtocol,AMCTreeNode>
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;

-(NSString*)displayText;

// "" (for not applicable), short, medium, long
@property (copy,readonly) NSString * hairLengthDescription;
@property (copy,readonly) NSString * deluxeDescription;
@property id<AMCTreeNode> parentNode;
@end

NS_ASSUME_NONNULL_END

#import "Service+CoreDataProperties.h"
