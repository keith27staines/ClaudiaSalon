//
//  AMCStaffBusyView.m
//  ClaudiasSalon
//
//  Created by service on 21/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCStaffBusyView.h"
#import "Employee.h"
#import "Appointment.h"
#import "Service.h"
#import "SaleItem.h"
#import "Customer.h"
#import "Sale.h"
#import "NSDate+AMCDate.h" 

typedef NS_ENUM(NSInteger, AMCEmployeeUtilisation) {
    AMCEmployeeUtilisationFree = 0,
    AMCEmployeeUtilisationPartiallyOccupied = 1,
    AMCEmployeeUtilisationFullyOccupied = 2,
    AMCEmployeeUtilisationOutOfHours = 4,
    AMCEmployeeUtilisationOnBreak = 5,
    AMCEmployeeUtilisationHoliday = 6,
    AMCEmployeeUtilisationIll = 7,
};

static const NSInteger space = 20;

@interface AMCStaffBusyView()
{
    NSDate * _startDate;
}
@property (readwrite) NSDate * startDate;
@property (readwrite) NSDate * endDate;
@property NSArray * employees;
@property NSArray * appointmentsOnDay;
@property NSDate * chartStartDate;
@property NSDate * chartEndDate;
@property NSInteger barLeft;
@property NSInteger barLength;
@property NSInteger chartStartHour;
@property NSInteger chartStopHour;
@property float yStart;
@property AMCSalonDocument * salonDocument;
@property NSLayoutConstraint * heightConstraint;
@end

@implementation AMCStaffBusyView

-(void)configureWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate salon:(AMCSalonDocument*)document {
    self.salonDocument = document;
    self.startDate = startDate;
    self.endDate = [endDate copy];
}
-(NSDate *)startDate {
    return _startDate;
}
-(void)setStartDate:(NSDate *)startDate {
    _startDate = [startDate copy];
    self.employees = [Employee allActiveEmployeesWithMoc:self.salonDocument.managedObjectContext];
    self.appointmentsOnDay = [Appointment appointmentsOnDayOfDate:startDate withMoc:self.salonDocument.managedObjectContext];
    self.appointmentsOnDay = [self.appointmentsOnDay filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"cancelled = NO"]];
    self.chartStartHour = 8;
    self.chartStopHour = 21;
    self.chartStartDate = [[self.startDate beginningOfDay] dateByAddingTimeInterval:self.chartStartHour*3600];
    self.chartEndDate = [[self.startDate beginningOfDay] dateByAddingTimeInterval:self.chartStopHour*3600];
    self.dateLabel.stringValue = [NSString stringWithFormat:@"%@ %@",[self.startDate stringNamingDayOfWeek],[self.startDate dayAndMonthString]];
    [self setNeedsDisplay:YES];
}
- (IBAction)earlierButtonClicked:(id)sender {
    self.startDate = [self.startDate dateByAddingTimeInterval:-24 * 3600];
}

- (IBAction)laterButtonClicked:(id)sender {
    self.startDate = [self.startDate dateByAddingTimeInterval:+24 * 3600];
}
-(BOOL)isFlipped {
    return  YES;
}
-(NSInteger)widthOfWidestName {
    NSInteger widest = 0;
    NSSize size;
    for (Employee * employee in self.employees) {
        size = [employee.firstName sizeWithAttributes:nil];
        if (size.width > widest) {
            widest = size.width;
        }
    }
    return widest;
}
- (void)drawRect:(NSRect)dirtyRect
{
    NSGraphicsContext * context = [NSGraphicsContext currentContext];
    [context saveGraphicsState];
    [super drawRect:dirtyRect];
    [[NSColor whiteColor] set];
    NSRectFill(self.bounds);
    self.yStart = space;
    NSPoint point = NSMakePoint(space, self.yStart);
    NSSize size = NSZeroSize;
    for (Employee * employee in self.employees) {
        size = [self drawEmployeeChart:employee fromPoint:(NSPoint)point];
        point = NSMakePoint(point.x, point.y + size.height + 4);
    }
    [self drawTimeAxisFromPoint:point toPoint:NSMakePoint(point.x + size.width, point.y)];
    [context restoreGraphicsState];
}
-(float)calculateHeight {
    float height = 4*space;
    for (Employee * employee in self.employees) {
        NSSize size = [employee.firstName sizeWithAttributes:nil];
        height += (size.height + 4);
    }
    return height;
}
-(void)updateConstraints {
    [super updateConstraints];
    if (self.heightConstraint) {
        [self removeConstraint:self.heightConstraint];
    }
    self.heightConstraint = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:0 multiplier:0 constant:[self calculateHeight]];
    [self addConstraint:self.heightConstraint];
}
-(NSSize)drawEmployeeChart:(Employee*)employee fromPoint:(NSPoint)point {
    NSSize size = [employee.firstName sizeWithAttributes:nil];
    [employee.firstName drawAtPoint:point withAttributes:nil];
    NSInteger widestNameWidth = [self widthOfWidestName];
    self.barLeft = point.x + widestNameWidth + space;
    self.barLength = self.bounds.size.width - self.barLeft - space;
    NSDate * startDate = self.chartStartDate;
    NSDate * endDate = [startDate dateByAddingTimeInterval:1800];
    while ([startDate isLessThan:self.chartEndDate]) {
        [[self colorFromStart:startDate endDate:endDate forEmployee:employee] set];
        float x1 = self.barLeft + [self xFractionFromDate:startDate] * self.barLength;
        float x2 = self.barLeft + [self xFractionFromDate:endDate] * self.barLength;
        float width = x2 - x1;
        NSRect busyBar = NSMakeRect(x1, point.y, width, size.height);
        [NSBezierPath fillRect:busyBar];
        startDate = [startDate dateByAddingTimeInterval:1800];
        endDate = [endDate dateByAddingTimeInterval:1800];
    }
    return size;
}
-(void)drawTimeAxisFromPoint:(NSPoint)startPoint toPoint:(NSPoint)endPoint1 {
    [[NSColor blackColor] set];
    [NSBezierPath setDefaultLineWidth:0];
    NSPoint axisStartPoint = NSMakePoint(self.barLeft, startPoint.y);
    NSPoint axisEndPoint = NSMakePoint(self.barLeft + self.barLength, startPoint.y);
    [NSBezierPath strokeLineFromPoint:axisStartPoint toPoint:axisEndPoint];
    
    NSDate * tickDate = self.chartStartDate;
    NSPoint tickStartPoint = NSMakePoint(axisStartPoint.x,axisStartPoint.y + space);
    NSPoint tickEndPoint = NSMakePoint(axisStartPoint.x, self.yStart);
    NSInteger hour = self.chartStartHour;
    while ([tickDate isLessThanOrEqualTo:self.chartEndDate]) {
        tickStartPoint.x = self.barLeft + self.barLength * [self xFractionFromDate:tickDate];
        tickEndPoint.x = tickStartPoint.x;
        [NSBezierPath strokeLineFromPoint:tickStartPoint toPoint:tickEndPoint];
        NSString * hourString = [NSString stringWithFormat:@"%li:00",(long)hour];
        NSSize size = [hourString sizeWithAttributes:nil];
        NSRect rect = NSMakeRect(tickStartPoint.x - size.width/2, tickStartPoint.y, size.width, size.height);
        [hourString drawInRect:rect withAttributes:nil];
        hour += 1;
        tickDate = [tickDate dateByAddingTimeInterval:3600];
    }
    // small ticks on half hour
    tickStartPoint.y = tickStartPoint.y - space/2 - 2;
    tickDate = [self.chartStartDate dateByAddingTimeInterval:1800];
    NSDictionary * textOptions = @{NSForegroundColorAttributeName:[NSColor darkGrayColor]};
    while ([tickDate isLessThan:self.chartEndDate]) {
        [[NSColor lightGrayColor] set];
        tickStartPoint.x = self.barLeft + self.barLength * [self xFractionFromDate:tickDate];
        tickEndPoint.x = tickStartPoint.x;
        [NSBezierPath strokeLineFromPoint:tickStartPoint toPoint:tickEndPoint];
        NSString * hourString = [NSString stringWithFormat:@":%i",30];
        NSSize size = [hourString sizeWithAttributes:textOptions];
        NSRect rect = NSMakeRect(tickStartPoint.x - size.width/2, tickStartPoint.y, size.width, size.height);
        [hourString drawInRect:rect withAttributes:textOptions];
        tickDate = [tickDate dateByAddingTimeInterval:3600];
    }
}

-(float)xFractionFromDate:(NSDate*)date {
    NSInteger t = [date timeIntervalSinceDate:self.chartStartDate];
    NSInteger max = [self.chartEndDate timeIntervalSinceDate:self.chartStartDate];
    return (float)t / (float)max;
}

-(NSColor*)colorFromStart:(NSDate*)startDate endDate:(NSDate*)endDate forEmployee:(Employee*)employee {
    AMCEmployeeUtilisation utilisation = [self employeeUtilisationFromStart:startDate endDate:endDate forEmployee:employee];
    return [self colorForEmployeeUtilisation:utilisation];
}
-(AMCEmployeeUtilisation)employeeUtilisationFromStart:(NSDate*)startDate endDate:(NSDate*)endDate forEmployee:(Employee*)employee {
    NSDate * dayStart = [startDate beginningOfDay];
    NSDate * businessStart = [dayStart dateByAddingTimeInterval:3600 * 10];
    NSDate * businessEnd = [dayStart dateByAddingTimeInterval:3600 * 19];
    AMCEmployeeUtilisation utilisation = AMCEmployeeUtilisationFree;
    if ([startDate isLessThan:businessStart] || [endDate isGreaterThan:businessEnd]) {
        utilisation = AMCEmployeeUtilisationOutOfHours;
    }
    
    for (Appointment * appointment in self.appointmentsOnDay) {
        if (appointment.cancelled.boolValue) continue;
        if ([self appointment:appointment overlapsStart:startDate endDate:endDate]) {
            AMCEmployeeUtilisation appointmentUtilisation = [self employee:employee utilisationForAppointment:appointment];
            utilisation = appointmentUtilisation;
            if (([startDate isLessThan:businessStart] || [endDate isGreaterThan:businessEnd]) && utilisation == AMCEmployeeUtilisationFree) {
                utilisation = AMCEmployeeUtilisationOutOfHours;
            }
        }
    }
    return utilisation;
}
-(BOOL)appointment:(Appointment*)appointment overlapsStart:(NSDate*)startDate endDate:(NSDate*)endDate {
    if ([appointment.appointmentDate isLessThan:endDate] && [appointment.appointmentEndDate isGreaterThan:startDate]) {
        return YES;
    }
    return NO;
}
-(AMCEmployeeUtilisation)employee:(Employee*)employee utilisationForAppointment:(Appointment*)appointment {
    if (appointment.cancelled.boolValue == YES) return AMCEmployeeUtilisationFree;
    BOOL involvesOthers = NO;
    BOOL involvesEmployee = NO;
    for (SaleItem * saleItem in appointment.sale.saleItem) {
        if (saleItem.performedBy == employee) {
            involvesEmployee = YES;
        } else {
            involvesOthers = YES;
        }
    }
    if (!involvesEmployee) {
        return AMCEmployeeUtilisationFree;
    } else {
        if (involvesOthers) {
            return AMCEmployeeUtilisationPartiallyOccupied;
        } else {
            return AMCEmployeeUtilisationFullyOccupied;
        }
    }
}
-(NSColor*)colorForEmployeeUtilisation:(AMCEmployeeUtilisation)utilisation {
    NSColor * veryLightGray = [NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0.9 alpha:0.8];
    NSColor * paleGreen = [NSColor colorWithCalibratedRed:0.5 green:1 blue:0.7 alpha:0.8];
    NSColor * paleBlue = [NSColor colorWithCalibratedRed:0.0 green:0.6 blue:1 alpha:0.8];
    NSColor * paleRed = [NSColor colorWithCalibratedRed:1 green:0.5 blue:0.5 alpha:0.8];
    switch (utilisation) {
        case AMCEmployeeUtilisationFree:
            return paleGreen;
        case AMCEmployeeUtilisationFullyOccupied:
            return paleRed;
        case AMCEmployeeUtilisationHoliday:
            return paleBlue;
        case AMCEmployeeUtilisationIll:
            return veryLightGray;
        case AMCEmployeeUtilisationOnBreak:
            return veryLightGray;
        case AMCEmployeeUtilisationOutOfHours:
            return veryLightGray;
        case AMCEmployeeUtilisationPartiallyOccupied:
            return [NSColor yellowColor];
    }
}


@end
