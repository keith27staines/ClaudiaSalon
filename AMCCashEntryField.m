//
//  AMCCashEntryField.m
//
//  Created by Keith Staines on 01/11/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCCashEntryField.h"
static NSSet * decimalSet;
@interface AMCCashEntryField ()
{
    NSColor * _backgroundColor;
    NSString * _string;
    NSMutableDictionary * _attributes;
    CGFloat _fontSize;
}
+(NSSet*)decimalSet;
@property NSMutableDictionary * attributes;
@property BOOL editsBegun;
@property BOOL isFirstResponder;
@end

@implementation AMCCashEntryField
+(NSSet *)decimalSet {
    if (!decimalSet) {
        NSArray * array = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9"];
        decimalSet = [NSSet setWithArray:array];
    }
    return decimalSet;
}
-(void)setBackgroundColor:(NSColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    [self setNeedsDisplay:YES];
}
-(NSColor *)backgroundColor {
    if (!_backgroundColor) {
        _backgroundColor = [NSColor yellowColor];
    }
    return _backgroundColor;
}
-(NSColor *)textColor {
    return self.attributes[NSForegroundColorAttributeName];
}
-(void)setTextColor:(NSColor *)textColor {
    self.attributes[NSForegroundColorAttributeName] = textColor;
    [self setNeedsDisplay:YES];
}
-(CGFloat)fontSize {
    return _fontSize;
}
-(void)setFontSize:(CGFloat)fontSize {
    _fontSize = fontSize;
    self.attributes[NSFontAttributeName] = [NSFont userFixedPitchFontOfSize:_fontSize];
    [self setNeedsDisplay:YES];
}
-(NSString *)string {
    if (!_string) {
        _string = @"";
    }
    return _string;
}
-(void)setString:(NSString *)string {
    _string = string;
    [self setNeedsDisplay:YES];
}
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [self.backgroundColor set];
    [NSBezierPath fillRect:self.bounds];
    NSString * displayString = [self displayNumber:self.string];
    NSSize stringSize = [displayString sizeWithAttributes:self.attributes];
    NSPoint origin = NSMakePoint(self.bounds.origin.x + self.bounds.size.width - stringSize.width, self.bounds.origin.y);// + self.bounds.size.height);// -(self.bounds.size.height-stringSize.height)/2.0);
    [displayString drawAtPoint:origin withAttributes:self.attributes];
    if (self.window.firstResponder == self && [NSGraphicsContext currentContextDrawingToScreen]) {
        [NSGraphicsContext saveGraphicsState];
        NSSetFocusRingStyle(NSFocusRingOnly);
        [NSBezierPath fillRect:self.bounds];
        [NSGraphicsContext restoreGraphicsState];
    }
}
-(NSMutableString*)displayNumber:(NSString*)str {
    NSMutableString *myNumber = [NSMutableString stringWithFormat:@"£%03lu", [str integerValue]];
    [myNumber insertString:@"." atIndex:myNumber.length-2];
    return myNumber;
}
-(BOOL)isOpaque {
    return YES;
}
-(BOOL)acceptsFirstResponder {
    return YES;
}
-(BOOL)resignFirstResponder {
    [self.delegate cashEntryDidEndEditing:self];
    [self setKeyboardFocusRingNeedsDisplayInRect:self.bounds];
    return YES;
}
-(BOOL)becomeFirstResponder {
    self.isFirstResponder = YES;
    self.editsBegun = NO;
    [self setNeedsDisplay:YES];
    return YES;
}
-(void)keyDown:(NSEvent *)theEvent {
    [self interpretKeyEvents:@[theEvent]];
    [self informDelegateOfChange];
}
-(void)addCharacter:(NSString *)ch {
    [self insertText:[ch substringToIndex:1]];
    [self informDelegateOfChange];
}
-(void)addDoubleZero {
    [self insertText:@"0"];
    [self insertText:@"0"];
    [self informDelegateOfChange];
}
-(void)clear {
    self.string = @" ";
    [self informDelegateOfChange];
}

-(void)informDelegateOfChange {
    if (self.isFirstResponder && !self.editsBegun) {
        self.editsBegun = YES;
        [self.delegate cashEntryDidBeginEditing:self];
    }
    [self.delegate cashEntryDidChange:self];
}

-(void)insertText:(NSString*)insertString {
    NSSet * decimalSet = [AMCCashEntryField decimalSet];
    if ([decimalSet containsObject:insertString]) {
        if ([self.string integerValue] < NSIntegerMax /100)
            self.string = [self.string stringByAppendingString:insertString];
        else
            NSBeep();
    }
}
-(void)insertNewline:(id)sender {
    [self endEditing];
    [self.window selectKeyViewFollowingView:self];
}
-(void)insertTab:(id)sender {
    [self endEditing];
    [self.window selectKeyViewFollowingView:self];
}
-(void)endEditing {
    self.editsBegun = false;
    [self.delegate cashEntryDidEndEditing:self];
}
-(void)insertBacktab:(id)sender {
    [self endEditing];
    [self.window selectKeyViewPrecedingView:self];
}
-(void)deleteBackward:(id)sender {
    [self clear];
}
-(NSMutableDictionary *)attributes {
    if (!_attributes) {
        _attributes = [NSMutableDictionary dictionary];
        _attributes[NSFontAttributeName] = [NSFont userFixedPitchFontOfSize:0];
        _attributes[NSForegroundColorAttributeName] = [NSColor redColor];
    }
    return _attributes;
}
-(void)setAttributes:(NSMutableDictionary *)attributes {
    _attributes = attributes;
    [self setNeedsDisplay:YES];
}
-(double)doubleValue {
    NSMutableString *myNumber = [NSMutableString stringWithFormat:@"%03lu", [self.string integerValue]];
    [myNumber insertString:@"." atIndex:myNumber.length-2];
    return myNumber.doubleValue;
}
-(void)setDoubleValue:(double)doubleValue {
    NSString * string = [NSString stringWithFormat:@"%1.2f",doubleValue];
    self.string = [string stringByReplacingOccurrencesOfString:@"." withString:@""];
}
@end
