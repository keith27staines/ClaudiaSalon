//
//  LastUpdatedBy.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 28/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LastUpdatedBy : NSManagedObject

@property (nonatomic, retain) NSString * computerIdentity;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * macAddress;
@property (nonatomic, retain) NSString * userIdentity;

@end
