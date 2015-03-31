//
//  StockedItem.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 31/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Note, StockedProduct;

@interface StockedItem : NSManagedObject

@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSNumber * percentageRemaining;
@property (nonatomic, retain) NSDate * purchaseDate;
@property (nonatomic, retain) NSDate * useByDate;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) StockedProduct *stockedProduct;
@end

@interface StockedItem (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

@end
