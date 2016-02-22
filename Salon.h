//
//  Salon.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 22/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AMCSalonDocument;
@class Account, AccountingPaymentGroup, Customer, Employee, OpeningHoursWeekTemplate, PaymentCategory, Role, ServiceCategory;

NS_ASSUME_NONNULL_BEGIN

@interface Salon : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

+(Salon*)salonWithMoc:(NSManagedObjectContext*)moc;
@end

NS_ASSUME_NONNULL_END

#import "Salon+CoreDataProperties.h"
