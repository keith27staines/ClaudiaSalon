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
@property NSLayoutConstraint * scrollViewHeight;
@end

@implementation AMCStaffBusyViewController

-(NSString *)nibName {
    return @"AMCStaffBusyViewController";
}
-(void)updateViewConstraints {
    [super updateViewConstraints];
    if (self.scrollViewHeight) {
        [self.scrollView removeConstraint:self.scrollViewHeight];
    }
    self.scrollViewHeight = [NSLayoutConstraint constraintWithItem:self.scrollView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationLessThanOrEqual toItem:self.staffBusyView attribute:NSLayoutAttributeHeight multiplier:1 constant:0];
    [self.scrollView addConstraint:self.scrollViewHeight];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self.staffBusyView configureWithStartDate:self.startDate endDate:self.endDate salon:self.salonDocument];
    [self.staffBusyView setNeedsDisplay:YES];
}



@end
