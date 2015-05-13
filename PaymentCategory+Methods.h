//
//  PaymentCategory+Methods.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "PaymentCategory.h"
#import "AMCSalonDocument.h"
@interface PaymentCategory (Methods)
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
+(PaymentCategory*)paymentWithName:(NSString*)name inMoc:(NSManagedObjectContext*)moc;
@end
