//
//  AMCBookingRowView.m
//  ClaudiasSalon
//
//  Created by service on 19/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCBookingRowView.h"
#import "Appointment+Methods.h"
#import "Customer+Methods.h"
#import "Service+Methods.h"
#import "Sale+Methods.h"
#import "SaleItem+Methods.h"
#import "Employee+Methods.h"

@interface AMCBookingRowView()
{
    Appointment * _appointment;
}
@property NSArray * saleItems;
@end


@implementation AMCBookingRowView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}
-(void)setAppointment:(Appointment *)appointment {
    _appointment = appointment;
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    NSString * startTime = [dateFormatter stringFromDate:appointment.appointmentDate];
    NSString * endTime = [dateFormatter stringFromDate:appointment.appointmentEndDate];
    self.appointmentTitleLabel.stringValue = [NSString stringWithFormat:@"%@ %@",appointment.customer.fullName,appointment.customer.phone];
    self.appointmentStartLabel.stringValue = startTime;
    self.appointmentEndLabel.stringValue = endTime;
    self.saleItems = [appointment.sale.saleItem allObjects];
    [self.servicesTable reloadData];
}
-(Appointment *)appointment {
    return _appointment;
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.appointment.sale.saleItem.count;
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    SaleItem * saleItem = self.saleItems[row];
    if ([tableColumn.identifier isEqualToString:@"serviceName"]) {
        return saleItem.service.name;
    }
    if ([tableColumn.identifier isEqualToString:@"stylistName"]) {
        return saleItem.performedBy.firstName;
    }
    if ([tableColumn.identifier isEqualToString:@"timeRequired"]) {
        return saleItem.service.expectedTimeRequired;
    }
    return nil;
}
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return NO;
}

@end
