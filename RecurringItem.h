//
//  RecurringItem.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Payment;

@interface RecurringItem : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * isActive;
@property (nonatomic, retain) NSNumber * period;
@property (nonatomic, retain) NSDate * nextActionDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * explanation;
@property (nonatomic, retain) Payment *paymentTemplate;

@end
