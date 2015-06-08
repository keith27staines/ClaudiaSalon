//
//  ServiceCategory.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 08/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Note, Salon, Service, ServiceCategory;

@interface ServiceCategory : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * hidden;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSDate * lastUpdatedDate;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * selectable;
@property (nonatomic, retain) NSNumber * isSystemCategory;
@property (nonatomic, retain) NSNumber * isDefaultCategory;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) NSSet *service;
@property (nonatomic, retain) ServiceCategory *parent;
@property (nonatomic, retain) NSSet *subCategories;
@property (nonatomic, retain) Salon *rootCategoryOfSalon;
@property (nonatomic, retain) Salon *salon;
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

- (void)addSubCategoriesObject:(ServiceCategory *)value;
- (void)removeSubCategoriesObject:(ServiceCategory *)value;
- (void)addSubCategories:(NSSet *)values;
- (void)removeSubCategories:(NSSet *)values;

@end
