//
//  Appointment+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Appointment+Methods.h"
#import "Sale+Methods.h"
#import "SaleItem+Methods.h"
#import "Service+Methods.h"
#import "NSDate+AMCDate.h"
#import "AMCConstants.h"

@implementation Appointment (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    Appointment * appointment = [NSEntityDescription insertNewObjectForEntityForName:@"Appointment" inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    appointment.createdDate = rightNow;
    appointment.lastUpdatedDate = rightNow;
    appointment.appointmentDate = [NSDate distantPast];
    appointment.bookedDuration = @(0);
    Sale * sale;
    sale = [Sale newObjectWithMoc:moc];
    sale.isQuote = @(YES);
    sale.hidden = @(YES);
    if ([appointment.appointmentDate isGreaterThan:[NSDate distantPast]]) {
        sale.createdDate = appointment.appointmentDate;
        sale.lastUpdatedDate = appointment.appointmentDate;
    } else {
        sale.createdDate = appointment.createdDate;
        sale.lastUpdatedDate = appointment.createdDate;
    }
    sale.customer = appointment.customer;
    appointment.sale = sale;
    return appointment;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"Appointment"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
-(NSNumber *)expectedTimeRequired
{
    double t = 0;
    for (SaleItem * saleItem in self.sale.saleItem) {
        t += saleItem.service.expectedTimeRequired.doubleValue;
    }
    return @(t);
}
-(NSUInteger)bookedDurationInMinutes {
    NSUInteger duration = self.bookedDuration.integerValue;
    return duration / 60;
}
-(NSDate*)appointmentEndDate {
    return [self.appointmentDate dateByAddingTimeInterval:self.bookedDuration.integerValue];
}
-(BOOL)conflictsWithAppointment:(Appointment*)otherAppointment {
    if (self.cancelled.boolValue == YES || otherAppointment.cancelled.boolValue == YES) {
        return NO;
    }
    if (self == otherAppointment) {
        return NO;
    }
    return [self conflictsWithInterval:otherAppointment.appointmentDate endOfInterval:otherAppointment.appointmentEndDate];
    return YES;
}
-(BOOL)conflictsWithInterval:(NSDate*)startDate endOfInterval:(NSDate*)endDate {
    if (self.cancelled.boolValue == YES) {
        return NO;
    }
    if ([self.appointmentDate isGreaterThanOrEqualTo:endDate]) {
        return NO;
    }
    if ([self.appointmentEndDate isLessThanOrEqualTo:startDate]) {
        return NO;
    }
    return YES;
}
+(NSArray*)appointmentsOnDayOfDate:(NSDate*)date withMoc:(NSManagedObjectContext*)moc{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Appointment" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    NSDate * startOfDay = [date beginningOfDay];
    NSDate * endOfDay = [date endOfDay];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"appointmentDate >= %@ and appointmentDate <= %@", startOfDay,endOfDay];
    [fetchRequest setPredicate:predicate];
    NSError *error = nil;
    NSArray *fetchedObjects = [moc executeFetchRequest:fetchRequest error:&error];
    return fetchedObjects;
}
-(NSArray*)conflictingAppointments {
    // As a good start, fetch all appointments on same day as these will be the only potential conflicts
    NSArray * potentialConflicts = [Appointment appointmentsOnDayOfDate:self.appointmentDate withMoc:self.managedObjectContext];
    // Now examine same-day appointments individually
    NSMutableArray * conflicts = [NSMutableArray array];
    for (Appointment * appointment in potentialConflicts) {
        if ([self conflictsWithAppointment:appointment]) {
            [conflicts addObject:appointment];
        }
    }
    return conflicts;
}
-(NSSet*)nonAuditNotes {
    NSMutableSet * nonAuditNotes = [NSMutableSet set];
    for (Note * note in self.notes) {
        if (!note.isAuditNote.boolValue) {
            [nonAuditNotes addObject:note];
        }
    }
    return nonAuditNotes;
}

@end
