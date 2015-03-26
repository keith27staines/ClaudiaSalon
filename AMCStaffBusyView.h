//
//  AMCStaffBusyView.h
//  ClaudiasSalon
//
//  Created by service on 21/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCStaffBusyView : NSView
@property (readonly) NSDate * startDate;
@property (readonly) NSDate * endDate;
-(void)configureWithStartDate:(NSDate*)startDate endDate:(NSDate*)endDate salon:(AMCSalonDocument*)salonDocument;

- (IBAction)earlierButtonClicked:(id)sender;

- (IBAction)laterButtonClicked:(id)sender;
@property (weak) IBOutlet NSTextField *dateLabel;

@end
