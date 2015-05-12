//
//  AMCBookingViewController.m
//  ClaudiasSalon
//
//  Created by service on 19/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCBookingViewController.h"
#import "Appointment+Methods.h"
#import "AMCBookingRowViewController.h"
#import "AMCBookingRowView.h"
#import "NSDate+AMCDate.h"

@interface AMCBookingViewController ()
{
    NSDate * _date;
}
@property NSArray * appointments;
@end

@implementation AMCBookingViewController

-(NSString *)nibName {
    return @"AMCBookingViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.appointments = [Appointment appointmentsOnDayOfDate:self.date withMoc:self.documentMoc];
    self.appointments = [self.appointments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"cancelled = NO"]];
    NSString * dateString = [NSString stringWithFormat:@"Appointments on %@ %@",[self.date stringNamingDayOfWeek], [self.date dayAndMonthString]];
    self.appontmentsForDateLabel.stringValue = dateString;
}

-(void)setDate:(NSDate *)date {
    _date = [date copy];
}
-(NSDate *)date {
    return [_date copy];
}
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.appointments.count;
}
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    Appointment * appointment = self.appointments[row];
    AMCBookingRowViewController * vc = [[AMCBookingRowViewController alloc] init];
    AMCBookingRowView * view = (AMCBookingRowView*)vc.view;
    view.appointment = appointment;
    return view;
}
-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 200;
}
@end
