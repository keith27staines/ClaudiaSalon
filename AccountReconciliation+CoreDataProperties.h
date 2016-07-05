//
//  AccountReconciliation+CoreDataProperties.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 04/07/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "AccountReconciliation.h"

NS_ASSUME_NONNULL_BEGIN

@interface AccountReconciliation (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *actualBalance;
@property (nullable, nonatomic, retain) NSString *bqCloudID;
@property (nullable, nonatomic, retain) NSNumber *bqHasClientChanges;
@property (nullable, nonatomic, retain) NSData *bqMetadata;
@property (nullable, nonatomic, retain) NSNumber *bqNeedsCoreDataExport;
@property (nullable, nonatomic, retain) NSNumber *isActive;
@property (nullable, nonatomic, retain) NSDate *lastUpdatedDate;
@property (nullable, nonatomic, retain) NSDate *reconciliationDate;
@property (nullable, nonatomic, retain) NSNumber *calculatedBalance;
@property (nullable, nonatomic, retain) Account *account;

@end

NS_ASSUME_NONNULL_END
