//
//  Appointment.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AMCObjectWithNotesProtocol.h"

@class Customer, Note, Sale;

NS_ASSUME_NONNULL_BEGIN

@interface Appointment : NSManagedObject <AMCObjectWithNotesProtocol>
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)appointmentsAfterDate:(NSDate*)date withMoc:(NSManagedObjectContext*)moc;
+(NSArray*)appointmentsOnDayOfDate:(NSDate*)date withMoc:(NSManagedObjectContext*)moc;
+(void)markAppointmentForExportInMoc:(NSManagedObjectContext*)parentMoc appointmentID:(NSManagedObjectID*)appointmentID;
-(NSNumber*)expectedTimeRequired;
-(NSUInteger)bookedDurationInMinutes;
-(BOOL)conflictsWithAppointment:(Appointment*)otherAppointment;
-(NSArray*)conflictingAppointments;
-(BOOL)conflictsWithInterval:(NSDate*)start endOfInterval:(NSDate*)end;
@end
NS_ASSUME_NONNULL_END

#import "Appointment+CoreDataProperties.h"


