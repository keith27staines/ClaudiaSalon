//
//  NSDate+AMCDate.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMCSalonDocument.h"
@interface NSDate (AMCDate)
+(NSDate*)beginningOfDayOnDate:(NSDate*)date;
+(NSDate*)endOfDayOnDate:(NSDate*)date;
-(NSDate*)beginningOfDay;
-(NSDate*)endOfDay;
-(NSString*)dateStringWithMediumDateFormatShortTimeFormat;
-(NSString*)stringNamingDayOfWeek;
-(NSString*)dayAndMonthString;
-(NSString*)stringAbbreviatingDayOfWeek;
-(NSString*)dateStringWithMediumDateFormat;
-(NSString*)timeStringWithShortFormat;
+(NSDate*)firstDayOfMonthContainingDate:(NSDate*)date;
+(NSDate*)lastDayOfMonthContainingDate:(NSDate*)date;
-(NSDate*)lastDayOfWeek;
-(NSDate*)firstDayOfWeek;
@end
