//
//  WizardStepViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 27/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "WizardStepViewController.h"

@interface WizardStepViewController ()
{
    EditMode _editMode;
}

@end

@implementation WizardStepViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (IBAction)toggleValidation:(id)sender
{
    [self.delegate wizardStep:self isValid:YES];
}
-(void)clearButton:(id)sender
{
    [self clear];
}
-(void)clear {
    
}
-(void)applyEditMode:(EditMode)editMode
{
    _editMode = editMode;
}
#pragma mark - WizardStepViewDelegate

-(void)viewRevisited:(NSView*)view
{
    
}
-(void)viewDidLoadFromNib:(NSView *)view
{
    
}
@end
