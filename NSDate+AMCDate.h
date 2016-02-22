//
//  NSDate+AMCDate.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
@class Salon;

#import <Foundation/Foundation.h>
@interface NSDate (AMCDate)
+(NSDate*)beginningOfDayOnDate:(NSDate*)date;
+(NSDate*)endOfDayOnDate:(NSDate*)date;
+(NSString*)stringNamingDayOfWeek:(NSInteger)cocoaDayNumber;
+(NSInteger)cocoaDayNumberForDayNamed:(NSString*)dayName;
-(NSDate*)beginningOfDay;
-(NSDate*)endOfDay;
-(NSString*)dateStringWithMediumDateFormatShortTimeFormat;
-(NSString*)stringNamingDayOfWeek;
-(NSString*)dayAndMonthString;
-(NSString*)stringAbbreviatingDayOfWeek;
-(NSString*)dateStringWithMediumDateFormat;
-(NSString*)timeStringWithShortFormat;
-(NSDate*)firstDayOfMonth;
-(NSDate*)lastDayOfMonth;
+(NSDate*)firstDayOfMonthContainingDate:(NSDate*)date;
+(NSDate*)lastDayOfMonthContainingDate:(NSDate*)date;
-(NSDate*)firstDayOfSalonWeek:(Salon*)salon;
-(NSDate*)lastDayOfSalonWeek:(Salon*)salon;
-(NSDate*)firstDayOfWeekWithFirstDay:(NSInteger)numberOfFirstDayInWeek;
-(NSDate*)lastDayOfWeekWithFirstDay:(NSInteger)numberOfFirstDayInWeek;
-(BOOL)isGreaterThan:(NSDate*)otherDate;
-(BOOL)isLessThan:(NSDate*)otherDate;
-(BOOL)isGreaterThanOrEqualTo:(NSDate*)otherDate;
-(BOOL)isLessThanOrEqualTo:(NSDate*)otherDate;

+(NSString*)monthNameFromNumber:(NSUInteger)number;

+(NSUInteger)daysInMonth:(NSUInteger)monthNumber;

@end
