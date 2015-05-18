//
//  AMCSalaryEditorViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//
@class AMCHoursWorkedEachDayOfWeekViewController;
#import "AMCSalaryEditorViewController.h"
#import "Employee+Methods.h"
#import "WorkRecord+Methods.h"
#import "Salary+Methods.h"
#import "AMCHoursWorkedEachDayOfWeekViewController.h"
#import "AMCHoursWorkedOnDayViewController.h"
#import "AMCSalaryCalculator.h"
#import "NSDate+AMCDate.h"

@interface AMCSalaryEditorViewController ()
{
    __weak Employee * _employee;
    NSDate * _salaryDate;
    AMCSalaryCalculator * _calculator;
}
@property (strong,readonly) AMCSalaryCalculator* calculator;
@property (strong) IBOutlet AMCHoursWorkedEachDayOfWeekViewController *hoursPerWeekViewController;
@property (weak) IBOutlet NSView *hoursWorkedPerWeekContainer;

@property BOOL isSalaryEditable;

@property (weak) IBOutlet NSView *containerView;
@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSButton *paidFromManagersBudgetCheckbox;

@property (weak) IBOutlet NSMatrix *salaryTypeRadioGroup;
@property (weak) IBOutlet NSButtonCell *payByHourRadioButton;
@property (strong) IBOutlet NSViewController *payByHourViewController;
@property (weak) IBOutlet NSButtonCell *payByPercentageRadioButton;
@property (weak) IBOutlet NSSlider *percentageSlider;
@property (weak) IBOutlet NSTextField *percentageLabel;

@property (strong) IBOutlet NSViewController *payByPercentageViewController;

@property (weak) IBOutlet NSTextField *extraHoursRate;

@property (weak) IBOutlet NSTextField *hourlyRateField;

@property (weak) IBOutlet NSTextField *dailyRateField;

@property (weak) IBOutlet NSTextField *weeklyRateField;

@property (weak) IBOutlet NSButton *previousSalaryButton;

@property (weak) IBOutlet NSButton *nextSalaryButton;

@property (weak) IBOutlet NSButton *currentSalaryButton;

@property (weak) IBOutlet NSDatePicker *validFromDate;

@property (weak) IBOutlet NSDatePicker *validToDate;
@property (weak) IBOutlet NSButton *createNewSalaryButton;

@property (weak) IBOutlet NSTextField *currentSalaryLabel;

@property (weak) IBOutlet NSTextField *validToLabel;


- (IBAction)hourlyRateChanged:(id)sender;

- (IBAction)weeklyRateChanged:(id)sender;

-(IBAction)extraHoursRateChanged:(id)sender;

-(IBAction)percentageChanged:(id)sender;

@property (weak) IBOutlet NSButton *fixSalaries;

@property (weak) Employee * employee;
@property (copy) NSDate * salaryDate;
@property Salary * salary;
@end

@implementation AMCSalaryEditorViewController
-(NSString *)nibName {
    return @"AMCSalaryEditorViewController";
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hoursWorkedOnDayChangedNotification:) name:@"hours worked on day changed" object:nil];
}
-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"hours worked on day changed" object:nil];
}
-(AMCSalaryCalculator *)calculator {
    if (!_calculator) {
        _calculator = [[AMCSalaryCalculator alloc] init];
    }
    return _calculator;
}
-(void)setEmployee:(Employee *)employee {
    _employee = employee;
    [self reloadData];
}
-(Employee *)employee {
    return _employee;
}
-(NSDate *)salaryDate {
    return [_salaryDate copy];
}
-(void)setSalaryDate:(NSDate *)salaryDate {
    _salaryDate = [salaryDate copy];
    [self reloadData];
}
- (IBAction)fixSalaries:(id)sender {   
//    NSArray * salaries = [[self.employee.salaries allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"validFromDate" ascending:YES]]];
//    for (Salary * salary in salaries) {
//        if ([salary.validFromDate isGreaterThanOrEqualTo:[NSDate date]]) {
//            [salary.managedObjectContext deleteObject:salary];
//        }
//    }
//    salaries = [[self.employee.salaries allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"validFromDate" ascending:YES]]];
//    Salary * previousSalary = nil;
//    Salary * thisSalary = nil;
//    Salary * nextSalary = nil;
//    for (NSInteger i = 0; i < salaries.count; i++) {
//        thisSalary = salaries[i];
//        if (i > 0) {
//            previousSalary = salaries[i-1];
//        }
//        if (i < salaries.count - 1) {
//            nextSalary = salaries[i+1];
//        }
//        if (previousSalary) {
//            thisSalary.validFromDate = [previousSalary.validToDate dateByAddingTimeInterval:1];
//            if ([thisSalary.validToDate isLessThanOrEqualTo:thisSalary.validFromDate]) {
//                thisSalary.validToDate = [thisSalary.validFromDate dateByAddingTimeInterval:24*3600];
//            }
//        }
//    }
//    thisSalary = [salaries lastObject];
//    thisSalary.validToDate = [NSDate distantFuture];
}

-(void)updateWithEmployee:(Employee*)employee forDate:(NSDate*)date {
    _employee = employee;
    _salaryDate = date;
    [self reloadData];
}
-(void)reloadData {
    [self view];
    if (self.employee) {
        self.titleLabel.stringValue = [NSString stringWithFormat:@"Salary for %@",self.employee.fullName];
    } else {
        self.titleLabel.stringValue = @"No employee specified";
    }
    self.salary = [self.employee salaryForDate:self.salaryDate];
    [self reloadHoursPerWeekView];
    if (self.salary) {
        self.validFromDate.dateValue = self.salary.validFromDate;
        self.validToDate.dateValue = self.salary.validToDate;
        self.paidFromManagersBudgetCheckbox.state = (self.employee.paidFromManagersBudget.boolValue)?NSOnState:NSOffState;

        // set allowed date ranges
        Salary * nextSalary = [self.employee salaryFollowingSalary:self.salary];
        Salary * previousSalary = [self.employee salaryPreceedingSalary:self.salary];
        if (nextSalary) {
            self.validToDate.maxDate = [nextSalary.validToDate dateByAddingTimeInterval:-2*24*3600];
        } else {
            self.validToDate.maxDate = [NSDate distantFuture];
        }
        if (previousSalary) {
            self.validFromDate.minDate = [previousSalary.validFromDate dateByAddingTimeInterval:2*24*3600];
        } else {
            self.validFromDate.minDate = [NSDate distantPast];
        }
        self.validToDate.minDate = [self.salary.validFromDate dateByAddingTimeInterval:24*3600];
        self.validFromDate.maxDate = [self.salary.validToDate dateByAddingTimeInterval:-24*3600];
        
        if ([self isCurrentSalary:self.salary]) {
            // Looking at current salary
            self.validToDate.minDate = [self.salary.validFromDate dateByAddingTimeInterval:1];;
            self.currentSalaryLabel.hidden = NO;
            self.currentSalaryButton.enabled = NO; // Already on current salary
            if ([self.salary.validToDate isEqual:[NSDate distantFuture]]) {
                // The current salary continues indefinitely
                self.createNewSalaryButton.enabled = YES;
                [self.validToDate setHidden:YES];
                [self.validToLabel setHidden:YES];
            } else {
                // The current salary has a proper end date
                self.createNewSalaryButton.enabled = NO;
                [self.validToDate setHidden:NO];
                [self.validToLabel setHidden:NO];
                [self.validToDate setEnabled:YES];
            }
        } else {
            // Looking at some salary which isn't the current salary
            self.currentSalaryLabel.hidden = YES;
            self.currentSalaryButton.enabled = YES;
            self.createNewSalaryButton.enabled = NO;
            if ([self.salary.validToDate isEqualToDate:[NSDate distantFuture]]) {
                [self.validToDate setHidden:YES];
                [self.validToLabel setHidden:YES];
                [self.validToDate setEnabled:NO];
            } else {
                [self.validToDate setHidden:NO];
                [self.validToLabel setHidden:NO];
                [self.validToDate setEnabled:NO];
            }
        }
        if ([self.employee salaryPreceedingSalary:self.salary]) {
            self.previousSalaryButton.enabled = YES;
        } else {
            self.previousSalaryButton.enabled = NO;
        }
        if ([self.employee salaryFollowingSalary:self.salary]) {
            self.nextSalaryButton.enabled = YES;
        } else {
            self.nextSalaryButton.enabled = NO;
        }
        if (self.salary.payByHour.boolValue) {
            self.payByHourRadioButton.state = NSOnState;
            self.payByPercentageRadioButton.state = NSOffState;
            [self reloadPayByHourView];
        } else {
            self.payByPercentageRadioButton.state = NSOnState;
            self.payByHourRadioButton.state = NSOffState;
            [self reloadPayByPercentView];
        }
    } else {
        [self updateForNoSalaryDate];
    }
    [self configureEditableControlsForSalary:self.salary];
}
-(void)configureEditableControlsForSalary:(Salary*)salary {
    // Just set the flag, the rest is taken care of by bindings
    self.isSalaryEditable = [self.calculator isSalaryModifiable:salary];
}
-(BOOL)isCurrentSalary:(Salary*)salary {
    NSDate * rightNow = [NSDate date];
    if ([salary.validFromDate isLessThanOrEqualTo:rightNow] && [salary.validToDate isGreaterThan:rightNow] ) {
        return YES;
    } else {
        return NO;
    }
}
-(void)reloadHoursPerWeekView {
    NSView * containerView = self.hoursWorkedPerWeekContainer;
    if (!containerView.subviews.firstObject) {
        NSView * view = self.hoursPerWeekViewController.view;
        NSDictionary * views = NSDictionaryOfVariableBindings(view);
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [containerView addSubview:view];
        [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views]];
        [containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views]];
    }
    self.hoursPerWeekViewController.workRecordTemplate = [self.employee ensureWorkRecordTemplateExists];
    self.hoursPerWeekViewController.endDate = [[NSDate date] lastDayOfSalonWeek:self.salonDocument.salon];
}
-(void)reloadPayByHourView {
    [self showSubview: self.payByHourViewController.view];
    [self reloadPayByHourViewData];
}
-(void)reloadPayByHourViewData {
    self.hourlyRateField.doubleValue = self.salary.hourlyRate.doubleValue;
    self.dailyRateField.doubleValue = self.salary.hourlyRate.doubleValue * 8;
    self.weeklyRateField.doubleValue = self.salary.weeklyRate.doubleValue;
    self.extraHoursRate.doubleValue = self.salary.extraHoursRate.doubleValue;
}
-(void)reloadPayByPercentView {
    [self showSubview: self.payByPercentageViewController.view];
    [self reloadPayByPercentViewData];
}
-(void)reloadPayByPercentViewData {
    int percentToEmployee = self.salary.percentage.doubleValue;
    int percentToSalon = 100 - percentToEmployee;
    self.percentageSlider.doubleValue = percentToSalon;
    self.percentageLabel.stringValue = [NSString stringWithFormat:@"%li %% to salon\n\n%li %% to employee",(long)percentToSalon,(long)percentToEmployee];
}
-(void)showSubview:(NSView*)view {
    [self removeContentViews];
    if (view) {
        [view setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.containerView addSubview:view];
        NSDictionary * views = NSDictionaryOfVariableBindings(view);
        NSArray * constraints;
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views];
        [self.containerView addConstraints:constraints];
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views];
        [self.containerView addConstraints:constraints];
    }
    [self.containerView setNeedsDisplay:YES];
}
-(void)removeContentViews {
    if (self.containerView.subviews.count == 0) {
        return;
    }
    NSView * view = self.containerView.subviews.firstObject;
    while (view) {
        [view removeFromSuperview];
        view = self.containerView.subviews.firstObject;
    }
}
-(void)updateForNoSalaryDate {
    [self removeContentViews];
}
- (IBAction)hourlyRateChanged:(id)sender {
    self.salary.hourlyRate = @(self.hourlyRateField.doubleValue);
    [self reloadPayByHourViewData];
}
- (IBAction)weeklyRateChanged:(id)sender {
    self.salary.weeklyRate = @(self.weeklyRateField.doubleValue);
    [self reloadPayByHourViewData];
}

- (IBAction)salaryTypeSetToPayByHour:(id)sender {
    self.salary.payByHour = @(YES);
    [self reloadPayByHourView];
}
- (IBAction)salaryTypeSetToPayByPercentage:(id)sender {
    self.salary.payByHour = @(NO);
    [self reloadPayByPercentView];
}
- (IBAction)percentageChanged:(id)sender {
    self.salary.percentage = @(100 - self.percentageSlider.doubleValue);
    [self reloadPayByPercentViewData];
}
-(IBAction)extraHoursRateChanged:(id)sender {
    self.salary.extraHoursRate = @(self.extraHoursRate.doubleValue);
}


- (IBAction)gotoPreviousSalary:(id)sender {
    self.salaryDate = [self.employee salaryPreceedingSalary:self.salary].validFromDate;
    [self reloadData];
}

- (IBAction)gotoNextSalary:(id)sender {
    self.salaryDate = [self.employee salaryFollowingSalary:self.salary].validFromDate;
    [self reloadData];
}

- (IBAction)gotoCurrentSalary:(id)sender {
    self.salaryDate = [NSDate date];
    [self reloadData];
}

- (IBAction)createNewSalary:(id)sender {
    Salary * salary = [self.employee endCurrentSalaryAndCreateNextOnDate:[[NSDate date] dateByAddingTimeInterval:-24*3600]];
    self.salaryDate = salary.validFromDate;
    [self reloadData];
}
- (IBAction)paidFromManagersBudgetChanged:(id)sender {
    self.employee.paidFromManagersBudget = (self.paidFromManagersBudgetCheckbox.state==NSOnState)?@YES:@NO;
}
- (IBAction)fromDateChanged:(id)sender {
    self.salary.validFromDate = [[self.validFromDate.dateValue dateByAddingTimeInterval:10] beginningOfDay];
    _salaryDate = self.salary.validFromDate;
    Salary * previousSalary = [self.employee salaryPreceedingSalary:self.salary];
    if (previousSalary) {
        previousSalary.validToDate = [[self.salary.validFromDate dateByAddingTimeInterval:-10] endOfDay];
    }
}
- (IBAction)toDateChanged:(id)sender {
    self.salary.validToDate = [[self.validToDate.dateValue endOfDay] dateByAddingTimeInterval:-1];
    _salaryDate = self.salary.validFromDate;
    Salary * nextSalary = [self.employee salaryFollowingSalary:self.salary];
    if (nextSalary) {
        nextSalary.validFromDate = [[self.salary.validToDate dateByAddingTimeInterval:10] beginningOfDay];
    }
}
-(void)hoursWorkedOnDayChangedNotification:(NSNotification*)notification {
    [self.hoursPerWeekViewController updateWorkRecordTemplateToMatchActual];
    double weeklyRate = self.salary.weeklyRate.doubleValue;
    AMCHoursWorkedEachDayOfWeekViewController * vc = self.hoursPerWeekViewController;
    double totalHours = vc.actualHoursWorked;
    double daysWorked = vc.actualDaysWorked;
    self.salary.nominalDaysPerWeek = @(daysWorked);
    if (daysWorked > 0) {
        self.salary.nominalHoursPerDay = @(totalHours / daysWorked);
    } else {
        self.salary.nominalHoursPerDay = @0;
    }
    self.salary.weeklyRate = @(weeklyRate);
    [self reloadPayByHourViewData];
}
-(void)dismissController:(id)sender {
    [self.presentingViewController dismissViewController:self];
}


@end
