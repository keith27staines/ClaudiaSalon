//
//  AMCDateRangeSelectorViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCDateRangeSelectorViewController.h"
#import "NSDate+AMCDate.h"

@interface AMCDateRangeSelectorViewController ()
{
    NSDate * _toDate;
    NSDate * _fromDate;
    NSDate * _lastReasonableFromDate;
    NSDate * _lastReasonableToDate;
}
@property (weak) IBOutlet NSView *containerView;

@property (weak) IBOutlet NSPopUpButton *rangeModeSelector;
- (IBAction)rangeModeChanged:(id)sender;

@property (strong) IBOutlet NSViewController *dateRangeViewController;
@property (strong) IBOutlet NSViewController *toDateViewController;
@property (strong) IBOutlet NSViewController *fromDateViewController;

@property (weak) IBOutlet NSDatePicker *dateRangeFromDatePicker;
@property (weak) IBOutlet NSDatePicker *dateRangeToDatePicker;
- (IBAction)fromDateChanged:(id)sender;

- (IBAction)toDateChanged:(id)sender;

@property (weak) IBOutlet NSDatePicker *toDatePicker;
@property (weak) IBOutlet NSDatePicker *fromDatePicker;

@property NSView * workingView;
@property NSDate * lastReasonableFromDate;
@property NSDate * lastReasonableToDate;
@end

typedef NS_ENUM(NSInteger, AMCDateRangeMode) {
    AMCDateRangeModeIncludeAll = 0,
    AMCDateRangeModeFromStartOfDate = 1,
    AMCDateRangeModeToEndOfDate = 2,
    AMCDateRangeModeSpecifiedRange = 3,
};

@implementation AMCDateRangeSelectorViewController

-(NSString *)nibName {
    return @"AMCDateRangeSelectorViewController";
}
-(NSDate *)lastReasonableFromDate {
    if (!_lastReasonableFromDate) {
        _lastReasonableFromDate = [[NSDate date] beginningOfDay];
    }
    return _lastReasonableFromDate;
}
-(void)setLastReasonableFromDate:(NSDate *)lastReasonableFromDate {
    _lastReasonableFromDate = [lastReasonableFromDate copy];
}
-(NSDate *)lastReasonableToDate {
    if (!_lastReasonableToDate) {
        _lastReasonableToDate = [[[NSDate date] endOfDay] dateByAddingTimeInterval:-1];;
    }
    return _lastReasonableToDate;
}
-(void)setLastReasonableToDate:(NSDate *)lastReasonableToDate {
    _lastReasonableToDate = [lastReasonableToDate copy];
}

-(void)viewDidLoad {
    [self.rangeModeSelector removeAllItems];
    NSMenuItem * menuItem;
    menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"Include all";
    menuItem.tag = AMCDateRangeModeIncludeAll;
    [self.rangeModeSelector.menu addItem:menuItem];
    menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"Everything after";
    menuItem.tag = AMCDateRangeModeFromStartOfDate;
    [self.rangeModeSelector.menu addItem:menuItem];
    menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"Everything before";
    menuItem.tag = AMCDateRangeModeToEndOfDate;
    [self.rangeModeSelector.menu addItem:menuItem];
    menuItem = [[NSMenuItem alloc] init];
    menuItem.title = @"Between dates";
    menuItem.tag = AMCDateRangeModeSpecifiedRange;
    [self.rangeModeSelector.menu addItem:menuItem];
    [self prepareRangeMode:AMCDateRangeModeIncludeAll];
}
-(void)prepareRangeMode:(AMCDateRangeMode)mode {
    if (self.workingView) {
        [self.workingView removeFromSuperview];
        self.workingView = nil;
    }
    switch (mode) {
        case AMCDateRangeModeIncludeAll:
            self.fromDate = [NSDate distantPast];
            self.toDate = [NSDate distantFuture];
            self.workingView = self.dateRangeViewController.view;
            self.dateRangeFromDatePicker.dateValue = self.fromDate;
            self.dateRangeToDatePicker.dateValue = self.toDate;
            [self.workingView setHidden:YES];
            break;
        case AMCDateRangeModeFromStartOfDate:
            self.workingView = self.fromDateViewController.view;
            if ([self.fromDate isLessThan:self.lastReasonableFromDate]) {
                self.fromDate = [self.lastReasonableFromDate copy];
            }
            self.lastReasonableFromDate = [self.fromDate copy];
            self.toDate = [NSDate distantFuture];
            self.fromDatePicker.dateValue = self.fromDate;
            break;
        case AMCDateRangeModeToEndOfDate:
            self.workingView = self.toDateViewController.view;
            if ([self.toDate isGreaterThan:self.lastReasonableToDate]) {
                self.toDate = [self.lastReasonableToDate copy];
            }
            self.lastReasonableToDate = [self.toDate copy];
            self.fromDate = [NSDate distantPast];
            self.toDatePicker.dateValue = self.toDate;
            break;
        case AMCDateRangeModeSpecifiedRange:
            self.workingView = self.dateRangeViewController.view;
            if ([self.fromDate isLessThan:self.lastReasonableFromDate]) {
                self.fromDate = [self.lastReasonableFromDate copy];
            }
            if ([self.toDate isGreaterThan:self.lastReasonableToDate]) {
                self.toDate = [self.lastReasonableToDate copy];
            }
            self.lastReasonableFromDate = [self.fromDate copy];
            self.lastReasonableToDate = [self.toDate copy];
            [self.workingView setHidden:NO];
            break;
        default:
            self.workingView = self.dateRangeViewController.view;
            if ([self.fromDate isLessThan:self.lastReasonableFromDate]) {
                self.fromDate = [self.lastReasonableFromDate copy];
            }
            if ([self.toDate isGreaterThan:self.lastReasonableToDate]) {
                self.toDate = [self.lastReasonableToDate copy];
            }
            self.lastReasonableFromDate = [self.fromDate copy];
            self.lastReasonableToDate = [self.toDate copy];
            [self.workingView setHidden:NO];
            break;
    }
    [self updateDateControls];
    NSAssert(self.workingView, @"Working view must not be nil");
    [self.rangeModeSelector selectItemWithTag:mode];
    [self.workingView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.containerView addSubview:self.workingView];
    NSView * view = self.workingView;
    NSDictionary * views = NSDictionaryOfVariableBindings(view);
    NSArray * constraints;
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views];
    [self.containerView addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views];
    [self.containerView addConstraints:constraints];
    [self.containerView setNeedsLayout:YES];
    [self.workingView setNeedsLayout:YES];
}

- (IBAction)rangeModeChanged:(id)sender {
    [self prepareRangeMode:self.rangeModeSelector.selectedTag];
}
-(NSDate *)toDate {
    if (!_toDate) {
        self.toDate = self.lastReasonableToDate;
    }
    return _toDate;
}
-(void)setToDate:(NSDate *)toDate {
    _toDate = [[toDate endOfDay] dateByAddingTimeInterval:-1];
    if ([_fromDate isGreaterThanOrEqualTo:_toDate]) {
        _fromDate = [_toDate beginningOfDay];
    }
    if ([toDate isLessThan:[NSDate distantFuture]]) {
        self.lastReasonableToDate = toDate;
    }
    [self updateDateControls];
}
-(NSDate *)fromDate {
    if (!_fromDate) {
        self.fromDate = self.lastReasonableFromDate;
    }
    return _fromDate;
}
-(void)setFromDate:(NSDate *)fromDate {
    _fromDate = [fromDate beginningOfDay];
    if ([_toDate isLessThanOrEqualTo:_fromDate]) {
        _toDate = [[_fromDate endOfDay] dateByAddingTimeInterval:-1];
    }
    if ([fromDate isGreaterThan:[NSDate distantPast]]) {
        self.lastReasonableFromDate = fromDate;
    }
    
    [self updateDateControls];
}
-(void)updateDateControls {
    NSAssert(self.dateRangeFromDatePicker!=nil, @"Range picker control is nil");
    NSAssert(self.dateRangeFromDatePicker.minDate!=nil, @"Min date is nil");
    if ([self.toDate isGreaterThan:self.dateRangeFromDatePicker.minDate] &&
        [self.toDate isLessThan:self.dateRangeFromDatePicker.maxDate]) {
        self.dateRangeToDatePicker.dateValue = self.toDate;
        self.toDatePicker.dateValue = self.toDate;
    }
    if ([self.fromDate isGreaterThan:self.dateRangeFromDatePicker.minDate] &&
        [self.fromDate isLessThan:self.dateRangeFromDatePicker.maxDate]) {
        self.dateRangeFromDatePicker.dateValue = self.fromDate;
        self.fromDatePicker.dateValue = self.fromDate;
    }
    [self.delegate dateRangeSelectorDidChange:self];
}
- (IBAction)fromDateChanged:(id)sender {
    NSDatePicker * picker = sender;
    self.fromDate = picker.dateValue;
}
- (IBAction)toDateChanged:(id)sender {
    NSDatePicker * picker = sender;
    self.toDate = picker.dateValue;
}
- (IBAction)selectEntireMonth:(id)sender {
    self.fromDate = [NSDate firstDayOfMonthContainingDate:self.fromDate];
    self.toDate = [NSDate lastDayOfMonthContainingDate:self.fromDate];
}
- (IBAction)selectNextMonth:(id)sender {
    NSDate * nextMonth = [NSDate firstDayOfMonthContainingDate:self.fromDate];
    nextMonth = [nextMonth dateByAddingTimeInterval:3600*24*32];
    self.fromDate = [NSDate firstDayOfMonthContainingDate:nextMonth];
    self.toDate = [NSDate lastDayOfMonthContainingDate:nextMonth];
}
- (IBAction)selectPreviousMonth:(id)sender {
    NSDate * previousMonth = [NSDate firstDayOfMonthContainingDate:self.fromDate];
    previousMonth = [previousMonth dateByAddingTimeInterval:-1];
    self.fromDate = [NSDate firstDayOfMonthContainingDate:previousMonth];
    self.toDate = [NSDate lastDayOfMonthContainingDate:previousMonth];
}


@end
