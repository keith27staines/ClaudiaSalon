//
//  AMCWizardStepViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCWizardStepViewController.h"
#import "AMCConstants.h"

@interface AMCWizardStepViewController ()
{
    id _objectToManage;
}
@end

@implementation AMCWizardStepViewController

-(NSString *)nibName {
    return @"AMCWizardStepViewController";
}
-(void)resetToObject {
    
}

-(void)setObjectToManage:(id)objectToManage
{
    if (objectToManage == _objectToManage) {
        return;
    }
    _objectToManage = objectToManage;
    [self resetToObject];
}
-(id)objectToManage {
    return _objectToManage;
}
@end
