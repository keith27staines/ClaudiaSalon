//
//  AMCCashEntryField.h
//
//  Created by Keith Staines on 01/11/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class AMCCashEntryField;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@protocol AMCCashEntryDelegate <NSObject>

-(void)cashEntryDidBeginEditing:(AMCCashEntryField*)cashEntryField;
-(void)cashEntryDidEndEditing:(AMCCashEntryField *)cashEntryField;
-(void)cashEntryDidChange:(AMCCashEntryField*)cashEntryField;
@end


@interface AMCCashEntryField : NSView
@property (copy) NSString * string;
@property (strong) NSColor * backgroundColor;
@property (strong) NSColor * textColor;
@property CGFloat fontSize;
-(void)clear;
-(void)addCharacter:(NSString*)ch;
-(void)addDoubleZero;
@property id<AMCCashEntryDelegate> delegate;

@property double doubleValue;
@end
