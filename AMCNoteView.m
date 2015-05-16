//
//  AMCNoteView.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCNoteView.h"
#import "Note.h"

@interface AMCNoteView ()
{
    NSColor * _backgroundColor;
    BOOL _isSelected;
}
@property NSColor * backgroundColor;
@end

@implementation AMCNoteView

-(NSColor *)backgroundColor {
    if (!_backgroundColor) {
        _backgroundColor = [NSColor whiteColor];
    }
    return _backgroundColor;
}
-(void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    if (isSelected) {
        self.backgroundColor = [NSColor colorWithCalibratedRed:0.6 green:0.8 blue:1 alpha:1];
    } else {
        self.backgroundColor = [NSColor whiteColor];
    }
    [self setNeedsDisplay:YES];
}
-(BOOL)isSelected {
    return _isSelected;
}
-(void)setBackgroundColor:(NSColor *)backgroundColor {
    _backgroundColor = backgroundColor;
}
-(void)drawRect:(NSRect)dirtyRect {
    [self.backgroundColor set];
    NSRectFill(dirtyRect);
}
- (IBAction)removeButtonClicked:(id)sender {
    if (self.target && self.removeAction) {
        [self.target performSelector:self.removeAction
                                 withObject:self
                                 afterDelay:0.0];
    }
}
@end
