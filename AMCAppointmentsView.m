//
//  AMCAppointmentsView.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCAppointmentsView.h"

@implementation AMCAppointmentsView

-(void)awakeFromNib
{
    [self.delegate appointmentsViewDidAwakeFromNib:self];
}

@end
