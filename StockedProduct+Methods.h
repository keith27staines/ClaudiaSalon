//
//  StockedProduct+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/12/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
@class StockedCategory;
#import "AMCSalonDocument.h"
#import "StockedProduct.h"
#import "AMCObjectWithNotesProtocol.h"

@interface StockedProduct (Methods) <AMCObjectWithNotesProtocol>
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
-(NSSet*)nonAuditNotes;
+(NSArray*)allProductsForCategory:(StockedCategory*)category withMoc:(NSManagedObjectContext*)moc;
+(StockedProduct*)fetchProductWithBarcode:(NSString*)barcode withMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allProductsForCategory:(StockedCategory*)category brand:(StockedBrand*)brand withMoc:(NSManagedObjectContext*)moc;
@end
