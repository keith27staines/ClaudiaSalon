//
//  RecurringItem+Methods.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 01/04/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "RecurringItem.h"
typedef NS_ENUM(NSInteger, AMCRecurrencePeriod) {
    AMCRecurrencePeriodNever = 0,
    AMCRecurrencePeriodWeekly = 1,
    AMCRecurrencePeriodMonthly = 2,
};
typedef NS_ENUM(NSInteger, AMCRecurrenceActionType) {
    AMCRecurrenceActionPayBill = 0,
};
@interface RecurringItem (Methods)

+(void)processOutstandingItemsFor:(NSManagedObjectContext*)moc error:(NSError**)error;
+(NSString*)nameOfReccurencePeriod:(AMCRecurrencePeriod)period;
+(NSString*)nameOfReccurenceAction:(AMCRecurrenceActionType)action;

@end
