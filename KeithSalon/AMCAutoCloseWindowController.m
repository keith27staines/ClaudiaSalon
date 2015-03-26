//
//  AMCAutoCloseWindowController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 04/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
#import "AMCAutoCloseWindowController.h"
#import "AMCAutoCloseViewController.h"

@interface AMCAutoCloseWindowController ()

@property (strong) IBOutlet AMCAutoCloseViewController *autoCloseViewController;
@end

@implementation AMCAutoCloseWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    NSView * view = self.autoCloseViewController.view;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.window.contentView addSubview:view];
    NSDictionary * views = NSDictionaryOfVariableBindings(view);
    [self.window.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views]];
    [self.window.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views]];
    self.window.title = @"MySalon will close";
}
-(NSString *)windowNibName {
    return @"AMCAutoCloseWindowController";
}
-(AppDelegate *)appDelegate {
    return self.autoCloseViewController.appDelegate;
}
-(void)setAppDelegate:(AppDelegate *)appDelegate {
    self.autoCloseViewController.appDelegate = appDelegate;
}
@end
