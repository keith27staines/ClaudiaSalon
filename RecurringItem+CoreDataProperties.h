//
//  RecurringItem+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "RecurringItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface RecurringItem (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *createdDate;
@property (nullable, nonatomic, retain) NSString *explanation;
@property (nullable, nonatomic, retain) NSNumber *isActive;
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *nameOfReccurencePeriod;
@property (nullable, nonatomic, retain) NSString *nameOfRecurringaction;
@property (nullable, nonatomic, retain) NSDate *nextActionDate;
@property (nullable, nonatomic, retain) NSNumber *period;
@property (nullable, nonatomic, retain) Payment *paymentTemplate;

@end

NS_ASSUME_NONNULL_END
