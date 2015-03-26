//
//  AMCHoursWorkedEachDayOfWeekViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

@class AMCHoursWorkedOnDayViewController;

#import "AMCHoursWorkedEachDayOfWeekViewController.h"
#import "AMCHoursWorkedOnDayViewController.h"
#import "WorkRecord+Methods.h"
#import "NSDate+AMCDate.h"

@interface AMCHoursWorkedEachDayOfWeekViewController ()
{
    NSDate * _endDate;
    WorkRecord * _defaultRecord;
}
@property NSMutableArray * dayViewControllers;
@property (weak) IBOutlet NSStackView *stackView;
@property NSMutableDictionary * dayViewControllerDictionary;

@end

@implementation AMCHoursWorkedEachDayOfWeekViewController
-(NSString *)nibName {
    return @"AMCHoursWorkedEachDayOfWeekViewController";
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self addDayViews];
}
-(void)addDayViews {
    if (self.dayViewControllers && self.dayViewControllers.count > 0) {
        return;
    }
    self.dayViewControllers = [NSMutableArray array];
    self.stackView.orientation = NSUserInterfaceLayoutDirectionLeftToRight;
    for (int i = 0; i < 7; i++) {
        AMCHoursWorkedOnDayViewController * vc = [[AMCHoursWorkedOnDayViewController alloc] init];
        [self.dayViewControllers addObject:vc];
        [vc.view setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.stackView addView:vc.view inGravity:NSStackViewGravityCenter];
    }
    [self workRecordTemplate:self.workRecordTemplate];
}
-(void)workRecordTemplate:(WorkRecord*)workRecordTemplate {
    if (!self.dayViewControllerDictionary || self.dayViewControllerDictionary.count == 0) {
        return;
    }
    NSArray * days = @[@"monday",@"tuesday",@"wednesday",@"thursday",@"friday",@"saturday",@"sunday"];
    for (NSString * day in days) {
        AMCHoursWorkedOnDayViewController * vc = self.dayViewControllerDictionary[day];
        if ([day isEqualToString:@"monday"]) {
            vc.hoursWorked = workRecordTemplate.monday.doubleValue;
        }
        if ([day isEqualToString:@"tuesday"]) {
            vc.hoursWorked = workRecordTemplate.tuesday.doubleValue;
        }
        if ([day isEqualToString:@"wednesday"]) {
            vc.hoursWorked = workRecordTemplate.wednesday.doubleValue;
        }
        if ([day isEqualToString:@"thursday"]) {
            vc.hoursWorked = workRecordTemplate.thursday.doubleValue;
        }
        if ([day isEqualToString:@"friday"]) {
            vc.hoursWorked = workRecordTemplate.friday.doubleValue;
        }
        if ([day isEqualToString:@"saturday"]) {
            vc.hoursWorked = workRecordTemplate.saturday.doubleValue;
        }
        if ([day isEqualToString:@"sunday"]) {
            vc.hoursWorked = workRecordTemplate.sunday.doubleValue;
        }
        vc.worked = (vc.hoursWorked > 0);
    }
}
-(NSDate *)endDate {
    return [_endDate copy];
}
-(void)setEndDate:(NSDate *)endDate {
    _endDate = [endDate copy];
    int i = -6;
    self.dayViewControllerDictionary = [NSMutableDictionary dictionary];
    for (AMCHoursWorkedOnDayViewController * vc in self.dayViewControllers) {
        vc.date = [endDate dateByAddingTimeInterval:i*24*3600];
        NSString * day = [[vc.date stringNamingDayOfWeek] lowercaseString];
        self.dayViewControllerDictionary[day] = vc;
        i++;
    }
    [self workRecordTemplate:self.workRecordTemplate];
}
-(WorkRecord *)workRecordTemplate {
    return _defaultRecord;
}
-(void)setWorkRecordTemplate:(WorkRecord *)workRecordTemplate {
    _defaultRecord = workRecordTemplate;
    [self workRecordTemplate:workRecordTemplate];
}
-(double)nominalHours {
    return self.workRecordTemplate.totalHoursForWeek.doubleValue;
}
-(double)actualHoursWorked {
    double actual = 0.0;
    for (NSString * key in self.dayViewControllerDictionary) {
        AMCHoursWorkedOnDayViewController * vc = self.dayViewControllerDictionary[key];
        actual += vc.hoursWorked;
    }
    return actual;
}
-(double)nominalDays {
    return self.workRecordTemplate.daysWorked.integerValue;
}
-(double)actualDaysWorked {
    double actual = 0.0;
    for (NSString * key in self.dayViewControllerDictionary) {
        AMCHoursWorkedOnDayViewController * vc = self.dayViewControllerDictionary[key];
        if (vc.worked) {
            actual++;
        };
    }
    return actual;
}
-(void)updateWorkRecordTemplateToMatchActual {
    for (NSString * key in self.dayViewControllerDictionary) {
        AMCHoursWorkedOnDayViewController * vc = self.dayViewControllerDictionary[key];
        [self.workRecordTemplate setHours:@(vc.hoursWorked) forDay:key];
    }
}
-(NSMutableDictionary *)hoursPerDayDictionary {
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    for (NSString * day in self.dayViewControllerDictionary) {
        AMCHoursWorkedOnDayViewController * vc = self.dayViewControllerDictionary[day];
        dictionary[day] = @(vc.hoursWorked);
    }
    return dictionary;
}
-(void)setHoursPerDayDictionary:(NSMutableDictionary *)hoursPerDayDictionary {
    for (NSString * key in self.dayViewControllerDictionary) {
        AMCHoursWorkedOnDayViewController * vc = self.dayViewControllerDictionary[key];
        vc.hoursWorked = ((NSNumber*)hoursPerDayDictionary[key]).doubleValue;
    }
}
@end
