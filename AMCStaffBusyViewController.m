//
//  AMCStaffBusyViewController.m
//  ClaudiasSalon
//
//  Created by service on 21/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCStaffBusyViewController.h"
#import "AMCStaffBusyView.h"

@interface AMCStaffBusyViewController ()
{
    
}

@end

@implementation AMCStaffBusyViewController

-(NSString *)nibName {
    return @"AMCStaffBusyViewController";
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self.staffBusyView configureWithStartDate:self.startDate endDate:self.endDate salon:self.salonDocument];
    [self.staffBusyView setNeedsDisplay:YES];
}



@end
