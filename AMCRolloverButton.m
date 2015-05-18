//
//  AMCRolloverButton.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 16/05/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCRolloverButton.h"

@implementation AMCRolloverButton


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}
-(void)viewDidMoveToWindow {
    NSTrackingArea* trackingArea = [[NSTrackingArea alloc]
                                    initWithRect:[self bounds]
                                    options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
                                    owner:self userInfo:nil];
    [self addTrackingArea:trackingArea];
    [self updateTrackingAreas];
    self.alphaValue = 0.0;
}
-(void)mouseEntered:(NSEvent *)theEvent {
    [[self animator]setAlphaValue:1.0];
    
}
-(void)mouseExited:(NSEvent *)theEvent {
    [[self animator]setAlphaValue:0.0];
    [self.cell setBackgroundColor:[NSColor whiteColor]];
    
}
-(void)updateTrackingAreas {
    [super updateTrackingAreas];
}
-(BOOL)sendAction:(SEL)theAction to:(id)theTarget {
    if (self.alphaValue > 0.9) {
        return [super sendAction:theAction to:theTarget];
    }
    return NO;
}
@end
