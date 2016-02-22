//
//  Customer.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AMCObjectWithNotesProtocol.h"
@class Appointment, Note, Sale, Salon;

NS_ASSUME_NONNULL_BEGIN

@interface Customer : NSManagedObject <AMCObjectWithNotesProtocol>
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc;
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc;
-(NSNumber*)totalMoneySpent;
-(NSNumber*)totalMoneyRefunded;
-(NSNumber*)numberOfPreviousVisits;
@end

NS_ASSUME_NONNULL_END

#import "Customer+CoreDataProperties.h"
