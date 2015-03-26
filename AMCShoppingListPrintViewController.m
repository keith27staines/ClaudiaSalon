//
//  AMCShoppingListPrintViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 04/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCShoppingListPrintViewController.h"
#import "AMCShoppingListPrintView.h"
#import "AMCSalonDocument.h"

@interface AMCShoppingListPrintViewController ()

@end

@implementation AMCShoppingListPrintViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [self.shoppingListView setNeedsDisplay:YES];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.shoppingListView.document = salonDocument;
    [self.shoppingListView reloadData];
    [self.shoppingListView setNeedsDisplay:YES];
}
-(NSString *)nibName {
    return @"AMCShoppingListPrintViewController";
}
-(IBAction)print:(id)sender {
    [self.shoppingListView print:sender];
    [self dismissController:self];
}
@end
