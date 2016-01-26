//
//  StockedCategory+CoreDataProperties.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "StockedCategory+CoreDataProperties.h"

@implementation StockedCategory (CoreDataProperties)

@dynamic categoryName;
@dynamic createdDate;
@dynamic fullDescription;
@dynamic notes;
@dynamic parentCategory;
@dynamic stockedProduct;
@dynamic subCategories;

@end
