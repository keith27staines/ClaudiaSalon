//
//  WizardStepViewController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 27/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class WizardStepViewController, WizardStepViewDelegate, Sale;
#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
#import "EditSaleViewController.h"
#import "WizardStepView.h"
#import "AMCWizardStepDelegate.h"

@interface WizardStepViewController : AMCViewController <WizardStepViewDelegate>

@property (weak) id objectForWizardStep;
@property BOOL isValid;
@property (weak) IBOutlet id<AMCWizardStepDelegate> delegate;

-(IBAction)clearButton:(id)sender;
-(void)clear;
-(void)applyEditMode:(EditMode)editMode;
@property (readwrite) EditMode editMode;
@end
