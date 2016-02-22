//
//  PaymentCategory.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AccountingPaymentGroup, Payment, Salon;

NS_ASSUME_NONNULL_BEGIN

@interface PaymentCategory : NSManagedObject
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
@end

NS_ASSUME_NONNULL_END

#import "PaymentCategory+CoreDataProperties.h"
