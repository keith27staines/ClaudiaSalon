//
//  Salon+Methods.m
//  ClaudiasSalon
//
//  Created by service on 16/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Salon+Methods.h"
#import "AppDelegate.h"
#import "LastUpdatedBy.h"
#import "OpeningHoursWeekTemplate.h"
#import "OpeningHoursDayTemplate.h"
#import "IntervalDuringDay.h"
#import "NSDate+AMCDate.h"
#import "Account+Methods.h"

@implementation Salon (Methods)
+(Salon*)salonWithMoc:(NSManagedObjectContext*)moc {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Salon" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    Salon * salon = nil;
    if (fetchedObjects.count == 0) {
        salon = [NSEntityDescription insertNewObjectForEntityForName:@"Salon" inManagedObjectContext:moc];
        salon.salonName = @"New Salon";
        salon.firstDayOfTrading = [NSDate date];
        salon.firstDayOfWeek = @(1);
        salon.endOfYear = salon.firstDayOfTrading;
        [salon addOpeningHoursWeekTemplate];
        [salon addDefaultAccounts];
    } else {
        salon = fetchedObjects[0];
        if (salon.firstDayOfWeek.integerValue == 0) {
            salon.firstDayOfWeek = @(1);// I, developer, messed up - days of week are 1-based!
        }
    }
    return salon;
}
-(void)addOpeningHoursWeekTemplate {
    OpeningHoursWeekTemplate * openingHoursWeekTemplate = [NSEntityDescription insertNewObjectForEntityForName:@"OpeningHoursWeekTemplate" inManagedObjectContext:self.managedObjectContext];
    openingHoursWeekTemplate.salon = self;
    for (int i = 0; i < 7; i++) {
        NSDate * day = [[[NSDate date] firstDayOfSalonWeek:self] dateByAddingTimeInterval:i*24*3600];
        OpeningHoursDayTemplate * openingHours = [NSEntityDescription insertNewObjectForEntityForName:@"OpeningHoursDayTemplate" inManagedObjectContext:self.managedObjectContext];
        openingHours.dayName = [day stringNamingDayOfWeek];
        IntervalDuringDay * interval = [NSEntityDescription insertNewObjectForEntityForName:@"IntervalDuringDay" inManagedObjectContext:self.managedObjectContext];
        interval.startTime = @(10 * 3600);
        interval.endTime = @(19 * 3600);
        openingHours.intervalDuringDay = interval;
        [openingHoursWeekTemplate addDayTemplatesObject:openingHours];
    }
}
-(void)addDefaultAccounts {
    NSArray * accounts = [Account allObjectsWithMoc:self.managedObjectContext];
    if (accounts.count == 0) {
        self.tillAccount = [Account newObjectWithMoc:self.managedObjectContext];
        self.cardPaymentAccount = [Account newObjectWithMoc:self.managedObjectContext];
        self.primaryBankAccount = [Account newObjectWithMoc:self.managedObjectContext];
        self.tillAccount.friendlyName = @"Till Account";
        self.cardPaymentAccount.friendlyName = @"Card Payment Account";
        self.primaryBankAccount.friendlyName = @"Primary bank account";
    }
}
@end
