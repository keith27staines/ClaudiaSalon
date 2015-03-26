//
//  AMCHoursWorkedOnDayViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCHoursWorkedOnDayViewController.h"
#import "NSDate+AMCDate.h"

@interface AMCHoursWorkedOnDayViewController ()
{
    NSDate * _date;
    double _hoursWorked;
    BOOL _worked;
    double _lastNonZeroHoursWorked;
}
@property (weak) IBOutlet NSBox *box;
@property (weak) IBOutlet NSTextField *dateField;
@property (weak) IBOutlet NSButton *workedCheckbox;
@property (weak) IBOutlet NSTextField *hoursWorkedTextField;
@property double lastNonZeroHoursWorked;

@end

@implementation AMCHoursWorkedOnDayViewController

-(NSString *)nibName {
    return @"AMCHoursWorkedOnDayViewController";
}
- (void)viewDidLoad {
    [super viewDidLoad];
}
- (IBAction)workedCheckboxChanged:(id)sender {
    self.worked = (self.workedCheckbox.state == NSOnState);
    [self.view.window makeFirstResponder:self.hoursWorkedTextField];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hours worked on day changed" object:self];
}
- (IBAction)hoursWorkedTextFieldChanged:(id)sender {
    self.hoursWorked = self.hoursWorkedTextField.doubleValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"hours worked on day changed" object:self];
}
-(NSDate *)date {
    return [_date copy];
}
-(double)lastNonZeroHoursWorked {
    if (_lastNonZeroHoursWorked <= 0) {
        _lastNonZeroHoursWorked = 8;
    }
    return _lastNonZeroHoursWorked;
}
-(void)setLastNonZeroHoursWorked:(double)lastNonZeroHoursWorked {
    _lastNonZeroHoursWorked = lastNonZeroHoursWorked;
}
-(void)setDate:(NSDate *)date {
    _date = [date copy];
    self.box.title = [[date stringNamingDayOfWeek] uppercaseString];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterNoStyle];
    self.dateField.stringValue = [formatter stringFromDate:date];
}
-(BOOL)worked {
    return _worked;
}
-(void)setWorked:(BOOL)worked {
    _worked = worked;
    if (worked) {
        [self.workedCheckbox setState:NSOnState];
        [self.hoursWorkedTextField setEnabled:YES];
        _hoursWorked = self.lastNonZeroHoursWorked;
    } else {
        [self.workedCheckbox setState:NSOffState];
        [self.hoursWorkedTextField setEnabled:NO];
        _hoursWorked = 0;
    }
}
-(double)hoursWorked {
    return _hoursWorked;
}
-(void)setHoursWorked:(double)hoursWorked {
    if (hoursWorked < 0) hoursWorked = 0;
    if (hoursWorked > 24) hoursWorked = 24;
    if (hoursWorked > 0) _lastNonZeroHoursWorked = hoursWorked;
    self.worked = (hoursWorked>0)?YES:NO;
    self.hoursWorkedTextField.stringValue = [NSString stringWithFormat:@"%1.2f hours",hoursWorked];
}
@end
