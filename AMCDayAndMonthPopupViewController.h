//
//  AMCDayAndMonthPopupLoader.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 28/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class AMCDayAndMonthPopupViewController;

#import <Foundation/Foundation.h>
#import "AMCSalonDocument.h"
@protocol AMCDayAndMonthPopupViewControllerDelegate <NSObject>

-(void)dayAndMonthControllerDidUpdate:(AMCDayAndMonthPopupViewController*)dayAndMonthController;

@end

@interface AMCDayAndMonthPopupViewController : NSObject

+(NSString*)monthNameFromNumber:(NSUInteger)number;

@property (weak) IBOutlet id<AMCDayAndMonthPopupViewControllerDelegate>delegate;
@property (weak) IBOutlet NSPopUpButton * monthPopupButton;
@property (weak) IBOutlet NSPopUpButton * dayPopupButton;

@property (readonly) NSUInteger monthNumber;
@property (readonly) NSUInteger dayNumber;
@property (copy,readonly) NSString * monthName;

- (IBAction)monthChanged:(NSPopUpButton *)sender;
- (IBAction)dayChanged:(id)sender;

-(void)selectMonthNumber:(NSUInteger)monthNumber dayNumber:(NSUInteger)dayNumber;

@property BOOL enabled;

@end
