//
//  AMCDateRangeSelectorViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@class AMCDateRangeSelectorViewController;

@protocol AMCDateRangeSelectorViewControllerDelegate <NSObject>

-(void)dateRangeSelectorDidChange:(AMCDateRangeSelectorViewController*)dateRangeSelector;

@end

@interface AMCDateRangeSelectorViewController : AMCViewController

@property NSDate * fromDate;
@property NSDate * toDate;
@property (readonly,copy) NSDate * lastReasonableFromDate;
@property (readonly,copy) NSDate *lastReasonableToDate;

@property (weak) IBOutlet id<AMCDateRangeSelectorViewControllerDelegate> delegate;
@end
