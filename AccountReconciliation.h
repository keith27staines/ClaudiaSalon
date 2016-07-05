//
//  AccountReconciliation.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Account;

NS_ASSUME_NONNULL_BEGIN

@interface AccountReconciliation : NSManagedObject
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
@end

NS_ASSUME_NONNULL_END

#import "AccountReconciliation+CoreDataProperties.h"
