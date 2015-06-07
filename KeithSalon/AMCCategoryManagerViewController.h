//
//  AMCCategoryManagerViewController.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 19/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCViewController.h"

typedef NS_ENUM(NSInteger, AMCCategoryType) {
    AMCCategoryTypeAll = 0,
    AMCCategoryTypePayments = 1,
    AMCCategoryTypeServices = 2
};

@interface AMCCategoryManagerViewController : AMCViewController
-(NSData*)dataForUserDefaultsRegistration;
@property AMCCategoryType categoryType;
@end
