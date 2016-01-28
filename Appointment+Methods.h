//
//  Appointment+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Appointment.h"
#import "AMCSalonDocument.h"
#import "AMCObjectWithNotesProtocol.h"

@interface Appointment (Methods) <AMCObjectWithNotesProtocol>
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)appointmentsAfterDate:(NSDate*)date withMoc:(NSManagedObjectContext*)moc;
+(NSArray*)appointmentsOnDayOfDate:(NSDate*)date withMoc:(NSManagedObjectContext*)moc;
-(NSNumber*)expectedTimeRequired;
-(NSUInteger)bookedDurationInMinutes;
-(BOOL)conflictsWithAppointment:(Appointment*)otherAppointment;
-(NSArray*)conflictingAppointments;
-(BOOL)conflictsWithInterval:(NSDate*)start endOfInterval:(NSDate*)end;
@end