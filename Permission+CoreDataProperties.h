//
//  Permission+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Permission.h"

NS_ASSUME_NONNULL_BEGIN

@interface Permission (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *createAction;
@property (nullable, nonatomic, retain) NSNumber *editAction;
@property (nullable, nonatomic, retain) NSNumber *viewAction;
@property (nullable, nonatomic, retain) BusinessFunction *businessFunction;
@property (nullable, nonatomic, retain) Role *role;

@end

NS_ASSUME_NONNULL_END
