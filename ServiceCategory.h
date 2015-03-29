//
//  ServiceCategory.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Note, Service;

@interface ServiceCategory : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * hidden;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSDate * lastUpdatedDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * selectable;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) NSSet *service;
@end

@interface ServiceCategory (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

- (void)addServiceObject:(Service *)value;
- (void)removeServiceObject:(Service *)value;
- (void)addService:(NSSet *)values;
- (void)removeService:(NSSet *)values;

@end
