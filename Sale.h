//
//  Sale.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AMCObjectWithNotesProtocol.h"

@class Account, Appointment, Customer, Note, Payment, SaleItem;

NS_ASSUME_NONNULL_BEGIN

@interface Sale : NSManagedObject <AMCObjectWithNotesProtocol>
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(void)markSaleForExportInMoc:(NSManagedObjectContext*)parentMoc saleID:(NSManagedObjectID*)saleID;
+(NSArray*)salesBetweenStartDate:(NSDate*)startDate endDate:(NSDate*)endDate withMoc:(NSManagedObjectContext*)moc;
+(Sale*)firstEverSaleWithMoc:(NSManagedObjectContext*)moc;
-(void)updatePriceFromSaleItems;
-(Payment*)makePaymentInFull;
-(Payment*)makePaymentOfAmount:(double)amount;
-(void)makeAdvancePayment:(double)amount inAccount:(Account*)account;
-(double)amountPaid;
-(double)amountPaidNet;
-(double)amountOutstanding;
-(double)amountAdvanced;
-(BOOL)isVoidable;
-(void)convertToDiscountVersion2;
-(NSArray*)activeSaleItems;
@end

NS_ASSUME_NONNULL_END

#import "Sale+CoreDataProperties.h"
