//
//  AMCHoursWorkedEachDayOfWeekViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//
@class WorkRecord;
#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCHoursWorkedEachDayOfWeekViewController : AMCViewController
@property (copy) NSDate * endDate;
@property WorkRecord * workRecordTemplate;
@property (readonly) NSMutableDictionary * dayViewControllerDictionary;
@property (readonly) double nominalHours;
@property (readonly) double actualHoursWorked;
@property (readonly) double nominalDays;
@property (readonly) double actualDaysWorked;
@property (copy) NSMutableDictionary * hoursPerDayDictionary;

-(void)updateWorkRecordTemplateToMatchActual;

@end
