//
//  AMCJobsColumnView.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 26/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
@class AMCJobsColumnView;

@protocol AMCJobsColumnViewDelegate

-(void)jobsColumnView:(AMCJobsColumnView*)view selectedStylist:(id)stylist;

@end
#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCJobsColumnView : NSTableCellView 
@property (weak) id<AMCJobsColumnViewDelegate>delegate;
@property id representedObject;

@property (weak) IBOutlet NSPopUpButton *stylistPopup;

- (IBAction)stylistChanged:(id)sender;
@end
