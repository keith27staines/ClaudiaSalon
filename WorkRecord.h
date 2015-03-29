//
//  WorkRecord.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Employee, Payment;

@interface WorkRecord : NSManagedObject

@property (nonatomic, retain) NSNumber * friday;
@property (nonatomic, retain) NSNumber * isTemplate;
@property (nonatomic, retain) NSNumber * monday;
@property (nonatomic, retain) NSNumber * saturday;
@property (nonatomic, retain) NSNumber * sunday;
@property (nonatomic, retain) NSNumber * thursday;
@property (nonatomic, retain) NSNumber * tuesday;
@property (nonatomic, retain) NSNumber * wednesday;
@property (nonatomic, retain) NSDate * weekEndingDate;
@property (nonatomic, retain) NSSet *bonuses;
@property (nonatomic, retain) Employee *employee;
@property (nonatomic, retain) NSSet *wages;
@property (nonatomic, retain) Employee *workRecordTemplateForEmployee;
@end

@interface WorkRecord (CoreDataGeneratedAccessors)

- (void)addBonusesObject:(Payment *)value;
- (void)removeBonusesObject:(Payment *)value;
- (void)addBonuses:(NSSet *)values;
- (void)removeBonuses:(NSSet *)values;

- (void)addWagesObject:(Payment *)value;
- (void)removeWagesObject:(Payment *)value;
- (void)addWages:(NSSet *)values;
- (void)removeWages:(NSSet *)values;

@end
