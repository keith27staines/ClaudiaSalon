//
//  AMCNoteView.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
#import "AMCRolloverButton.h"
#import "AMCNoteView.h"
#import "Note.h"

@interface AMCNoteView ()
{
    NSColor * _backgroundColor;
    BOOL _isSelected;
}
@property NSColor * backgroundColor;
@property (weak) IBOutlet AMCRolloverButton *closeButton;

@end

@implementation AMCNoteView

-(void)viewDidMoveToWindow {

}
-(NSColor *)backgroundColor {
    if (!_backgroundColor) {
        _backgroundColor = [NSColor whiteColor];
    }
    return _backgroundColor;
}
-(void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
//    if (isSelected) {
//        self.backgroundColor = [NSColor colorWithCalibratedRed:86./255. green:191.0/255.0 blue:1 alpha:1];
//    } else {
//        self.backgroundColor = [NSColor whiteColor];
//    }
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
    [[NSColor lightGrayColor] set];
    [NSBezierPath strokeRect:NSInsetRect(self.bounds, 1, 1)];
}
- (IBAction)removeButtonClicked:(id)sender {
    if (self.target && self.removeAction) {
        [self.target performSelector:self.removeAction
                                 withObject:self
                                 afterDelay:0.0];
    }
}

@end
