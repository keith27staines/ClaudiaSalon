//
//  WorkRecord.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "WorkRecord.h"
#import "Employee.h"
#import "Payment.h"
#import "NSDate+AMCDate.h"

@implementation WorkRecord 
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    WorkRecord *record = [NSEntityDescription insertNewObjectForEntityForName:@"WorkRecord" inManagedObjectContext:moc];
    record.monday    = @8;
    record.tuesday   = @8;
    record.wednesday = @8;
    record.thursday  = @8;
    record.friday    = @8;
    record.saturday  = @8;
    record.sunday    = @8;
    record.isTemplate = @NO;
    return record;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"WorkRecord"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
-(NSNumber*)totalHoursForWeek {
    return @(self.monday.doubleValue +
    self.tuesday.doubleValue +
    self.wednesday.doubleValue +
    self.thursday.doubleValue +
    self.friday.doubleValue +
    self.saturday.doubleValue +
    self.sunday.doubleValue);
}
-(NSNumber*)daysWorked {
    int n = 0;
    if (self.monday.doubleValue > 0) n++;
    if (self.tuesday.doubleValue > 0) n++;
    if (self.wednesday.doubleValue > 0) n++;
    if (self.thursday.doubleValue > 0) n++;
    if (self.friday.doubleValue > 0) n++;
    if (self.saturday.doubleValue > 0) n++;
    if (self.sunday.doubleValue > 0) n++;
    return @(n);
}
-(NSNumber*)hoursForDay:(NSString*)dayName {
    NSString * lowerDayName = [dayName lowercaseString];
    if ([lowerDayName isEqualToString:@"monday"]) return self.monday;
    if ([lowerDayName isEqualToString:@"tuesday"]) return self.tuesday;
    if ([lowerDayName isEqualToString:@"wednesday"]) return self.wednesday;
    if ([lowerDayName isEqualToString:@"thursday"]) return self.thursday;
    if ([lowerDayName isEqualToString:@"friday"]) return self.friday;
    if ([lowerDayName isEqualToString:@"saturday"]) return self.saturday;
    if ([lowerDayName isEqualToString:@"sunday"]) return self.sunday;
    NSAssert(NO, @"Day name %@ is not recognised",dayName);
    return nil;
}
-(void)setHours:(NSNumber*) hours forDay:(NSString*)dayName {
    NSString * lowerDayName = [dayName lowercaseString];
    if ([lowerDayName isEqualToString:@"monday"]) { self.monday = hours; return; };
    if ([lowerDayName isEqualToString:@"tuesday"]) { self.tuesday = hours; return; };
    if ([lowerDayName isEqualToString:@"wednesday"]) { self.wednesday = hours; return; };
    if ([lowerDayName isEqualToString:@"thursday"]) { self.thursday = hours; return; };
    if ([lowerDayName isEqualToString:@"friday"]) { self.friday = hours; return; };
    if ([lowerDayName isEqualToString:@"saturday"]) { self.saturday = hours; return; };
    if ([lowerDayName isEqualToString:@"sunday"]) { self.sunday = hours; return; };
    NSAssert(NO, @"Day name %@ is not recognised",dayName);
}
-(NSDictionary*)hoursWorkedDictionary {
    return @{@"monday": self.monday,
             @"tuesday": self.tuesday,
             @"wednesday": self.wednesday,
             @"thursday": self.thursday,
             @"friday": self.friday,
             @"saturday": self.saturday,
             @"sunday": self.sunday};
}
-(void)setHoursWorkedDictionary:(NSDictionary*)dictionary {
    NSMutableDictionary * templateHours = [[self hoursWorkedDictionary] mutableCopy];
    for (NSString * key in dictionary) {
        if (!templateHours[key]) {
            NSAssert(NO, @"%@ is not a valid day name",key);
        } else {
            [self setHours:dictionary[key] forDay:key];
            [templateHours removeObjectForKey:key];
        }
    }
}
-(NSDate*)weekBeginningDate {
    return [[self.weekEndingDate dateByAddingTimeInterval:-7*24*3600] beginningOfDay];
}
@end

