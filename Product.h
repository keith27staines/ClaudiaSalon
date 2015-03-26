//
//  Product.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Note, Service;

@interface Product : NSManagedObject

@property (nonatomic, retain) NSString * brandName;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * hidden;
@property (nonatomic, retain) NSDate * lastUpdatedDate;
@property (nonatomic, retain) NSString * productType;
@property (nonatomic, retain) NSNumber * selectable;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) Service *service;
@end

@interface Product (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

@end
