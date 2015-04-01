//
//  RecurringItem.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 01/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Payment;

@interface RecurringItem : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * explanation;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * nameOfReccurencePeriod;
@property (nonatomic, retain) NSString * nameOfRecurringaction;
@property (nonatomic, retain) NSDate * nextActionDate;
@property (nonatomic, retain) NSNumber * period;
@property (nonatomic, retain) Payment *paymentTemplate;

@end
