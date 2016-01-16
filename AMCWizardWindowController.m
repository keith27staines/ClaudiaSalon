//
//  AMCWizardWindowController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCWizardWindowController.h"
#import "AMCWizardStepViewController.h"

@interface AMCWizardWindowController ()
{
    NSUInteger _selectedIndex;
    NSMutableArray * _wizardStepControllers;
}
@end

@implementation AMCWizardWindowController

#pragma mark - NSViewController overrides
-(NSString *)windowNibName {
    return @"AMCWizardWindowController";
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self addWizardStepControllers];
    if (self.wizardStepControllers.count > 0) {
        [self selectWizardStep:0];
    }
}
#pragma mark - methods that ought to be overriden
-(void)addWizardStepControllers {
    _wizardStepControllers = [NSMutableArray array];
}

-(NSString*)titleForStepWithIndex:(NSUInteger)index {
    return @"To set this title, override titleForStepWithIndex:";
}

#pragma mark - methods designed to be (optionally!) overriden
-(BOOL)wizardStepCanBeSkippedWithIndex:(NSUInteger)index {
    return NO;
}
-(void)updateEnabledAndVisiblePropertiesForWizardButton:(NSButton*)wizardButton onWizardStep:(NSUInteger)step {
    return;
}
-(void)selectWizardStep:(NSUInteger)index
{
    if (index > self.wizardStepControllers.count - 1) {
        _selectedIndex = self.wizardStepControllers.count - 1;
    } else {
        _selectedIndex = index;
    }
    [self removeOldStep];
    [self addCurrentStep];
    [self.selectedStepController resetToObject];
}

#pragma mark - methods not designed to be overriden
-(NSMutableArray *)wizardStepControllers {
    if (!_wizardStepControllers) {
        _wizardStepControllers = [NSMutableArray array];
    }
    return _wizardStepControllers;
}
-(void)setWizardStepControllers:(NSMutableArray *)wizardStepControllers {
    _wizardStepControllers = wizardStepControllers;
}
-(AMCWizardStepViewController *)selectedStepController {
    return self.wizardStepControllers[self.selectedIndex];
}
-(void)addWizardStepViewController:(AMCWizardStepViewController *)wizardStepViewController {
    [self.wizardStepControllers addObject:wizardStepViewController];
}
-(void)removeWizardStepViewController:(AMCWizardStepViewController*)wizardStepViewController {
    [self.wizardStepControllers removeObject:wizardStepViewController];
}
#pragma mark - AMCWizardStepViewControllerDelegate
-(void)wizardStepControllerDidChangeState:(AMCWizardStepViewController*)controller {
    [self configureWizardButtons];
}
#pragma mark - Helpers
-(void)addCurrentStep {
    AMCWizardStepViewController * vc = self.wizardStepControllers[self.selectedIndex];
    vc.delegate = self;
    [vc prepareForDisplayWithSalon:self.document];
    NSView * view = vc.view;
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.wizardPanelTitleLabel.stringValue = [self titleForStepWithIndex:self.selectedIndex];
    [self.stepContainerView addSubview:view];
    NSArray * constraints;
    NSDictionary * views = NSDictionaryOfVariableBindings(view);
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views];
    [self.stepContainerView addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views];
    [self.stepContainerView addConstraints:constraints];
    [self configureWizardButtons];
}
-(void)removeOldStep
{
    while (self.stepContainerView.subviews.count > 0) {
        NSView * view = self.stepContainerView.subviews[0];
        [view removeFromSuperview];
    }
}
-(void)configureWizardButtons
{
    NSUInteger currentIndex = self.selectedIndex;
    AMCWizardStepViewController * currentStep = self.selectedStepController;
    BOOL isLastStep = (self.selectedIndex == self.wizardStepControllers.count - 1)?YES:NO;
    if (currentStep.isValid) {
        if (isLastStep) {
            [self.nextButton setEnabled:NO];
            [self.doneButton setEnabled:YES];
            [self.window setDefaultButtonCell:[self.doneButton cell]];
        } else {
            [self.nextButton setEnabled:YES];
            [self.doneButton setEnabled:NO];
            [self.window setDefaultButtonCell:[self.nextButton cell]];
        }
    } else {
        if (isLastStep) {
            [self.nextButton setEnabled:NO];
            [self.doneButton setEnabled:([self wizardStepCanBeSkippedWithIndex:currentIndex])];
        } else {
            [self.nextButton setEnabled:([self wizardStepCanBeSkippedWithIndex:currentIndex])];
            [self.doneButton setEnabled:NO];
        }
    }
    [self.previousButton setEnabled:(currentIndex > 0)];
    [self updateEnabledAndVisiblePropertiesForWizardButton:self.nextButton onWizardStep:self.selectedIndex];
    [self updateEnabledAndVisiblePropertiesForWizardButton:self.doneButton onWizardStep:self.selectedIndex];
}
#pragma mark - Actions
- (IBAction)cancelButtonClicked:(id)sender {
    self.cancelled = YES;
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}
- (IBAction)previousButtonClicked:(id)sender {
    [self selectWizardStep:self.selectedIndex - 1];
}
- (IBAction)nextButtonClicked:(id)sender {
    [self selectWizardStep:self.selectedIndex + 1];
}
- (IBAction)doneButtonClicked:(id)sender {
    self.cancelled = NO;
    [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}
@end
