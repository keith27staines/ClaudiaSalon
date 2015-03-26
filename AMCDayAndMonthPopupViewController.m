//
//  AMCDayAndMonthPopupLoader.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 28/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCDayAndMonthPopupViewController.h"

@interface AMCDayAndMonthPopupViewController ()
{
    NSUInteger _monthNumber;
    NSUInteger _dayNumber;
    BOOL _enabled;
}
@end

@implementation AMCDayAndMonthPopupViewController

-(void)awakeFromNib
{
    self.enabled = YES;
    [self loadMonthPopupButton];
    [self selectMonthNumber:0 dayNumber:0];
}

- (IBAction)monthChanged:(NSPopUpButton *)sender {
    _monthNumber = [self.monthPopupButton indexOfSelectedItem];
    [self loadDayOfMonthPopupForMonthNumber:_monthNumber];
    if (_dayNumber > [self daysInMonth:_monthNumber]) {
        _dayNumber = [self daysInMonth:_monthNumber];
    }
    [self.dayPopupButton selectItemAtIndex:_dayNumber];
    [self.delegate dayAndMonthControllerDidUpdate:self];
}
- (IBAction)dayChanged:(id)sender
{
    _dayNumber = [self.dayPopupButton indexOfSelectedItem];
    [self.delegate dayAndMonthControllerDidUpdate:self];
}
-(void)selectMonthNumber:(NSUInteger)monthNumber dayNumber:(NSUInteger)dayNumber
{
    _monthNumber = monthNumber;
    _dayNumber = dayNumber;
    NSAssert(monthNumber >=0 && monthNumber < 13, @"Month number out of range");
    [self.monthPopupButton selectItemAtIndex:monthNumber];
    [self loadDayOfMonthPopupForMonthNumber:monthNumber];
    if (dayNumber > [self daysInMonth:monthNumber]) {
        dayNumber = 0;
    }
    [self.dayPopupButton selectItemAtIndex:dayNumber];
}
-(void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    [self.monthPopupButton setEnabled:enabled];
    [self.dayPopupButton setEnabled:enabled];
}
-(BOOL)enabled
{
    return _enabled;
}
-(NSString *)monthName
{
    return [self monthNameFromNumber:self.monthNumber];
}
-(NSString*)monthNameFromNumber:(NSUInteger)number {
    return [[self class] monthNameFromNumber:number];
}
+(NSString*)monthNameFromNumber:(NSUInteger)number
{
    switch (number) {
        case 1:
            return @"January";
            break;
        case 2:
            return @"February";
            break;
        case 3:
            return @"March";
            break;
        case 4:
            return @"April";
            break;
        case 5:
            return @"May";
            break;
        case 6:
            return @"June";
            break;
        case 7:
            return @"July";
            break;
        case 8:
            return @"August";
            break;
        case 9:
            return @"September";
            break;
        case 10:
            return @"October";
            break;
        case 11:
            return @"November";
            break;
        case 12:
            return @"December";
        default:
            return @"Month";
            break;
    }
}

-(NSUInteger)daysInMonth:(NSUInteger)monthNumber
{
    switch (monthNumber) {
        case 0:
            return 0;
        case 1:
            return 31;
            break;
        case 2:
            return 28;
            break;
        case 3:
            return 31;
            break;
        case 4:
            return 30;
            break;
        case 5:
            return 31;
            break;
        case 6:
            return 30;
            break;
        case 7:
            return 31;
            break;
        case 8:
            return 31;
            break;
        case 9:
            return 30;
            break;
        case 10:
            return 31;
            break;
        case 11:
            return 30;
            break;
        case 12:
            return 31;
            break;
    }
    return 0;
}
-(void)loadMonthPopupButton
{
    [self.monthPopupButton removeAllItems];
    for (int i = 0; i < 13; i++) {
        NSString * title = [self monthNameFromNumber:i];
        [self.monthPopupButton insertItemWithTitle:title atIndex:i];
    }
    [self.monthPopupButton selectItemAtIndex:0];
}
-(void)loadDayOfMonthPopupForMonthNumber:(NSUInteger)monthNumber
{
    NSUInteger currentlySelectedDay = [self.dayPopupButton indexOfSelectedItem];
    [self.dayPopupButton removeAllItems];
    NSUInteger daysInMonth = [self daysInMonth:monthNumber];
    NSString * title;
    for (int i = 0; i <= daysInMonth; i++) {
        if (i==0) {
            title = @"Day";
        } else {
            title = [NSString stringWithFormat:@"%i",i];
        }
        [self.dayPopupButton insertItemWithTitle:title atIndex:i];
    }
    if (currentlySelectedDay <= daysInMonth) {
        [self.dayPopupButton selectItemAtIndex:currentlySelectedDay];
    } else {
        [self.dayPopupButton selectItemAtIndex:0];
    }
}
@end
