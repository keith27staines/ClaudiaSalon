//
//  WizardStepView.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 02/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "WizardStepView.h"

@implementation WizardStepView


-(void)viewDidMoveToWindow
{
    if (self.window) {
        [self.delegate viewRevisited:self];
    }
}

@end
