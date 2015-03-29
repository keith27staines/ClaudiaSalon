//
//  StockedCategory.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Note, StockedCategory, StockedProduct;

@interface StockedCategory : NSManagedObject

@property (nonatomic, retain) NSString * categoryName;
@property (nonatomic, retain) NSDate * createdDate;
@property (nonatomic, retain) NSString * fullDescription;
@property (nonatomic, retain) NSSet *notes;
@property (nonatomic, retain) StockedCategory *parentCategory;
@property (nonatomic, retain) NSSet *stockedProduct;
@property (nonatomic, retain) NSSet *subCategories;
@end

@interface StockedCategory (CoreDataGeneratedAccessors)

- (void)addNotesObject:(Note *)value;
- (void)removeNotesObject:(Note *)value;
- (void)addNotes:(NSSet *)values;
- (void)removeNotes:(NSSet *)values;

- (void)addStockedProductObject:(StockedProduct *)value;
- (void)removeStockedProductObject:(StockedProduct *)value;
- (void)addStockedProduct:(NSSet *)values;
- (void)removeStockedProduct:(NSSet *)values;

- (void)addSubCategoriesObject:(StockedCategory *)value;
- (void)removeSubCategoriesObject:(StockedCategory *)value;
- (void)addSubCategories:(NSSet *)values;
- (void)removeSubCategories:(NSSet *)values;

@end
