//
//  Permission.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 27/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BusinessFunction, Role;

@interface Permission : NSManagedObject

@property (nonatomic, retain) NSNumber * viewAction;
@property (nonatomic, retain) NSNumber * editAction;
@property (nonatomic, retain) NSNumber * createAction;
@property (nonatomic, retain) Role *role;
@property (nonatomic, retain) BusinessFunction *businessFunction;

@end
