//
//  Sale+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "Sale.h"
#import "AMCSalonDocument.h"
#import "AMCObjectWithNotesProtocol.h"

@interface Sale (Methods) <AMCObjectWithNotesProtocol>

+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(NSArray*)salesBetweenStartDate:(NSDate*)startDate endDate:(NSDate*)endDate withMoc:(NSManagedObjectContext*)moc;
+(Sale*)firstEverSaleWithMoc:(NSManagedObjectContext*)moc;
-(void)updatePriceFromSaleItems;
-(Payment*)makePaymentInFull;
-(Payment*)makePaymentOfAmount:(double)amount;
-(double)amountPaid;
-(double)amountPaidNet;
-(double)amountOutstanding;
@end
