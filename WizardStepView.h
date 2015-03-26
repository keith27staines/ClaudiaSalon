//
//  WizardStepView.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 02/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"

@protocol WizardStepViewDelegate

-(void)viewRevisited:(NSView*)view;
-(void)viewDidLoadFromNib:(NSView*)view;

@end


@interface WizardStepView : NSView

@property (weak) IBOutlet id<WizardStepViewDelegate>delegate;

@end
