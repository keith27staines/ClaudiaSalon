//
//  NSDate+AMCDate.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "NSDate+AMCDate.h"
#import "Salon.h"

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
-(NSDate*)firstDayOfMonth {
    return [NSDate firstDayOfMonthContainingDate:self];
}
-(NSDate*)lastDayOfMonth {
    return [NSDate lastDayOfMonthContainingDate:self];
}
-(NSDate*)lastDayOfSalonWeek:(Salon*)salon {
    return [self lastDayOfWeekWithFirstDay:salon.firstDayOfWeek.integerValue];
}
-(NSDate*)lastDayOfWeekWithFirstDay:(NSInteger)numberOfFirstDayInWeek {
    return [[[[self firstDayOfWeekWithFirstDay:numberOfFirstDayInWeek] dateByAddingTimeInterval:7*24*3600] dateByAddingTimeInterval:-1] beginningOfDay];
}
-(NSDate*)firstDayOfWeekWithFirstDay:(NSInteger)numberOfFirstDayInWeek {
    NSString * firstDay = [[NSDate stringNamingDayOfWeek:numberOfFirstDayInWeek] lowercaseString];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *startOfWeek;
    [calendar rangeOfUnit:NSCalendarUnitWeekOfYear
                startDate:&startOfWeek
                 interval:nil
                  forDate:self];
    startOfWeek = [[self beginningOfDay] dateByAddingTimeInterval:12*3600]; // work on midday to avoid rounding problems;
    if ( [[[startOfWeek stringNamingDayOfWeek] lowercaseString] isEqualToString:firstDay] ) {
        return [startOfWeek beginningOfDay];
    } else {
        while ( ![[[startOfWeek stringNamingDayOfWeek] lowercaseString] isEqualToString:firstDay] ) {
            startOfWeek = [startOfWeek dateByAddingTimeInterval:-24*3600];
        }
    }
    return [startOfWeek beginningOfDay];
}
-(NSDate*)firstDayOfSalonWeek:(Salon*)salon {
    return [self firstDayOfWeekWithFirstDay:salon.firstDayOfWeek.integerValue];
}
+(NSString*)stringNamingDayOfWeek:(NSInteger)cocoaDayNumber {
    switch (cocoaDayNumber) {
        case 1:
            return @"Sunday";
        case 2:
            return @"Monday";
        case 3:
            return @"Tuesday";
        case 4:
            return @"Wednesday";
        case 5:
            return @"Thursday";
        case 6:
            return @"Friday";
        case 7:
            return @"Saturday";
        default:
            return @"Unknown";
    }
}
+(NSInteger)cocoaDayNumberForDayNamed:(NSString*)dayName {
    if ([[dayName lowercaseString] isEqualToString:@"sunday"]) return 1;
    if ([[dayName lowercaseString] isEqualToString:@"monday"]) return 2;
    if ([[dayName lowercaseString] isEqualToString:@"tuesday"]) return 3;
    if ([[dayName lowercaseString] isEqualToString:@"wednesday"]) return 4;
    if ([[dayName lowercaseString] isEqualToString:@"thursday"]) return 5;
    if ([[dayName lowercaseString] isEqualToString:@"friday"]) return 6;
    if ([[dayName lowercaseString] isEqualToString:@"saturday"]) return 7;
    return 0;
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
