//
//  LastUpdatedBy+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 26/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "LastUpdatedBy.h"

NS_ASSUME_NONNULL_BEGIN

@interface LastUpdatedBy (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *computerIdentity;
@property (nullable, nonatomic, retain) NSDate *date;
@property (nullable, nonatomic, retain) NSString *macAddress;
@property (nullable, nonatomic, retain) NSString *userIdentity;

@end

NS_ASSUME_NONNULL_END
