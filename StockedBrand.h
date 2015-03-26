//
//  StockedBrand.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Note, StockedProduct;

@interface StockedBrand : NSManagedObject

@property (nonatomic, retain) NSString * brandName;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * shortBrandName;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) NSSet *stockedProducts;
@end

@interface StockedBrand (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

- (void)addStockedProductsObject:(StockedProduct *)value;
- (void)removeStockedProductsObject:(StockedProduct *)value;
- (void)addStockedProducts:(NSSet *)values;
- (void)removeStockedProducts:(NSSet *)values;

@end
