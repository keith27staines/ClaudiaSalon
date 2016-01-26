//
//  Appointment+CoreDataProperties.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Appointment+CoreDataProperties.h"

@implementation Appointment (CoreDataProperties)

@dynamic appointmentDate;
@dynamic appointmentEndDate;
@dynamic bookedDuration;
@dynamic cancellationNote;
@dynamic cancellationType;
@dynamic cancelled;
@dynamic completed;
@dynamic completionNote;
@dynamic completionType;
@dynamic createdDate;
@dynamic lastUpdatedDate;
@dynamic bqMetadata;
@dynamic bqNeedsCoreDataExport;
@dynamic customer;
@dynamic notes;
@dynamic sale;

@end
