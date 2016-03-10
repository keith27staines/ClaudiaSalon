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


@interface Salon : NSManagedObject

// Insert code here to declare functionality of your managed object subclass

+(Salon * _Nonnull)salonWithMoc:(NSManagedObjectContext* _Nonnull)moc;
+(Salon * _Nullable)defaultSalon:(NSManagedObjectContext * _Nonnull)moc;

@end

#import "Salon+CoreDataProperties.h"
