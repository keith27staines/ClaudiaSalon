//
//  AMCAppointmentsView.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
@class AMCAppointmentsView;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@protocol AMCAppointmentsViewDelegate <NSObject>

-(void)appointmentsViewDidAwakeFromNib:(AMCAppointmentsView*)appointmentsView;

@end

@interface AMCAppointmentsView : NSView

@property (weak) IBOutlet id<AMCAppointmentsViewDelegate>delegate;
@property (weak) IBOutlet NSSegmentedControl * intervalPickerSegmentedControl;



@end
