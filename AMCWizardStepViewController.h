//
//  AMCWizardStepViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
@class AMCWizardStepViewController;
#import <Cocoa/Cocoa.h>
#import "AMCConstants.h"
#import "AMCSalonDocument.h"
@protocol AMCWizardStepViewControllerDelegate <NSObject>

-(void)wizardStepControllerDidChangeState:(AMCWizardStepViewController*)controller;

@end

@interface AMCWizardStepViewController : AMCViewController

#pragma mark - Methods subclasses should override
@property (readonly) BOOL isValid;
-(void)resetToObject;

#pragma mark - Methods not to be overridden
@property (strong) id objectToManage;
@property (weak) id<AMCWizardStepViewControllerDelegate>delegate;

@end
