//
//  AMCStorePopulator.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 11/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMCSalonDocument.h"
@interface AMCStorePopulator : NSObject
+(BOOL)populateCategories:(AMCSalonDocument*)document error:(NSError *__autoreleasing *)error;

@end
