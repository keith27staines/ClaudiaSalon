//
//  AMCWizardStepDelegate.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 24/02/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
@class WizardStepViewController;

#import <Foundation/Foundation.h>

@protocol AMCWizardStepDelegate

-(Sale*)wizardStepRequiresSale:(WizardStepViewController *)wizardStep;
-(void)wizardStep:(WizardStepViewController*)wizardStep isValid:(BOOL)validity;

@end
