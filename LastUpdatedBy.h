//
//  LastUpdatedBy.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LastUpdatedBy : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * computerIdentity;
@property (nonatomic, retain) NSString * userIdentity;
@property (nonatomic, retain) NSString * macAddress;

@end
