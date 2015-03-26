//
//  AMCReportsView.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class AMCReportsView;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@protocol AMCRecportsViewDelegate <NSObject>

-(void)reportsViewDidAppear:(AMCReportsView*)reportsView;

@end


@interface AMCReportsView : NSView
@property (weak) IBOutlet  id<AMCRecportsViewDelegate>delegate;
@end
