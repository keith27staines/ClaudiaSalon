//
//  NSDate+AMCDate.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "NSDate+AMCDate.h"

@implementation NSDate (AMCDate)
+(NSDate*)beginningOfDayOnDate:(NSDate*)date
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    return [gregorian dateFromComponents:components];
}
+(NSDate *)endOfDayOnDate:(NSDate *)date
{
    NSDate * beginningOfDay = [NSDate beginningOfDayOnDate:date];
    return [beginningOfDay dateByAddingTimeInterval:24*3600];
}
-(NSDate *)beginningOfDay
{
    return [NSDate beginningOfDayOnDate:self];
}
-(NSDate *)endOfDay
{
    return [NSDate endOfDayOnDate:self];
}
-(NSDate*)lastDayOfWeek {
    return [[[[self firstDayOfWeek] dateByAddingTimeInterval:7*24*3600] dateByAddingTimeInterval:-1] beginningOfDay];
}
-(NSDate*)firstDayOfWeek {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *startOfWeek;
    [calendar rangeOfUnit:NSCalendarUnitWeekOfYear
                startDate:&startOfWeek
                 interval:nil
                  forDate:self];
    startOfWeek = [[self beginningOfDay] dateByAddingTimeInterval:12*3600]; // work on midday to avoid rounding problems;
    if ( [[startOfWeek stringNamingDayOfWeek] isEqualToString:@"Saturday"] ) {
        return [startOfWeek beginningOfDay];
    } else
        while ( ![[startOfWeek stringNamingDayOfWeek] isEqualToString:@"Saturday"] ) {
            startOfWeek = [startOfWeek dateByAddingTimeInterval:-24*3600];
        }
    return [startOfWeek beginningOfDay];
}
-(NSString*)dateStringWithMediumDateFormatShortTimeFormat {
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    return [formatter stringFromDate:self];
}
-(NSString*)dateStringWithMediumDateFormat {
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterNoStyle];
    return [formatter stringFromDate:self];
}
-(NSString*)timeStringWithShortFormat {
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterNoStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    return [formatter stringFromDate:self];
}
-(NSString*)stringAbbreviatingDayOfWeek {
    NSDateFormatter* theDateFormatter = [[NSDateFormatter alloc] init];
    [theDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [theDateFormatter setDateFormat:@"EEE"]; // EEE signifies abbreviated day name
    return [theDateFormatter stringFromDate:self];
}
-(NSString*)stringNamingDayOfWeek {
    NSDateFormatter* theDateFormatter = [[NSDateFormatter alloc] init];
    [theDateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [theDateFormatter setDateFormat:@"EEEE"]; // EEEE signifies full day name
    return [theDateFormatter stringFromDate:self];
}
-(NSString*)dayAndMonthString {
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    return [formatter stringFromDate:self];
}
+(NSDate*)firstDayOfMonthContainingDate:(NSDate*)date {
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:date];
    [components setDay:1];
    return [[gregorian dateFromComponents:components] beginningOfDay];

}
+(NSDate*)lastDayOfMonthContainingDate:(NSDate*)date {
    NSDate * firstDay = [NSDate firstDayOfMonthContainingDate:date];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [gregorian components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:firstDay];
    [components setMonth:components.month+1];
    return [[[gregorian dateFromComponents:components] beginningOfDay] dateByAddingTimeInterval:-1];
}
@end
