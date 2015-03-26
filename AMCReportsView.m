//
//  AMCReportsView.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCReportsView.h"

@implementation AMCReportsView

-(void)viewDidUnhide
{
    [self.delegate reportsViewDidAppear:self];
}
-(void)viewDidMoveToWindow
{
    if (self.window) {
        [self.delegate reportsViewDidAppear:self];
    }
}

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

@end
