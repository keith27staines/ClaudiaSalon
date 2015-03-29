//
//  Appointment.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Customer, Note, Sale;

@interface Appointment : NSManagedObject

@property (nonatomic, retain) NSDate * appointmentDate;
@property (nonatomic, retain) NSDate * appointmentEndDate;
@property (nonatomic, retain) NSNumber * bookedDuration;
@property (nonatomic, retain) NSString * cancellationNote;
@property (nonatomic, retain) NSNumber * cancellationType;
@property (nonatomic, retain) NSNumber * cancelled;
@property (nonatomic, retain) NSNumber * completed;
@property (nonatomic, retain) NSString * completionNote;
@property (nonatomic, retain) NSNumber * completionType;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSDate * lastUpdatedDate;
@property (nonatomic, retain) Customer *customer;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) Sale *sale;
@end

@interface Appointment (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

@end
