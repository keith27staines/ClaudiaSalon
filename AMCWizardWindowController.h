//
//  AMCWizardWindowController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class AMCWizardWindowController;

@protocol AMCWizardWindowControllerDelegate
-(void)wizardWindowControllerDidFinish:(AMCWizardWindowController*)controller;


@end

#import <Cocoa/Cocoa.h>
#import "AMCWizardStepViewController.h"
#import "AMCSalonDocument.h"
@interface AMCWizardWindowController : NSWindowController <AMCWizardStepViewControllerDelegate>
#pragma mark - methods that ought to be overridden
-(NSString*)titleForStepWithIndex:(NSUInteger)index;
-(void)addWizardStepControllers;

#pragma mark - methods designed to be overriden (but optional)
// Override this if steps can be skipped even if in an invalid state
-(BOOL)wizardStepCanBeSkippedWithIndex:(NSUInteger)index;

// override this to take control of the visibility and enabled properties of the wizard buttons
-(void)updateEnabledAndVisiblePropertiesForWizardButton:(NSButton*)wizardButton onWizardStep:(NSUInteger)step;

#pragma mark - methods not designed to be overriden
@property NSMutableArray * wizardStepControllers;

-(void)addWizardStepViewController:(AMCWizardStepViewController*)wizardStepViewController;
-(void)removeWizardStepViewController:(AMCWizardStepViewController*)wizardStepViewController;
@property (readonly) NSUInteger selectedIndex;
@property (readonly) AMCWizardStepViewController * selectedStepController;
-(void)selectWizardStep:(NSUInteger)index;

@property EditMode editMode;
@property BOOL cancelled;

#pragma mark - Outlets
@property (weak) IBOutlet id<AMCWizardWindowControllerDelegate>delegate;
@property (weak) IBOutlet NSTextField *wizardPanelTitleLabel;
@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSButton *previousButton;
@property (weak) IBOutlet NSButton *nextButton;
@property (weak) IBOutlet NSButton *doneButton;
@property (weak) IBOutlet NSView *stepContainerView;
@property (strong) id objectToManage;

#pragma mark - Actions
- (IBAction)cancelButtonClicked:(id)sender;
- (IBAction)previousButtonClicked:(id)sender;
- (IBAction)nextButtonClicked:(id)sender;
- (IBAction)doneButtonClicked:(id)sender;

@end
