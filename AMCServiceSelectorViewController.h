//
//  AMCServiceSelectorViewController.h
//  ClaudiasSalon
//
//  Created by service on 14/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
@class Sale, Service, AMCServiceSelectorViewController;

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@protocol AMCServiceSelectorViewControllerDelegate <NSObject>

-(void)serviceSelectorDidChangeSelection:(AMCServiceSelectorViewController*)serviceSelector;

@end

@interface AMCServiceSelectorViewController : AMCViewController <NSTableViewDelegate, NSTableViewDataSource>

@property Service * service;

@property (weak) IBOutlet NSPopUpButton *serviceCategoryPopup;

- (IBAction)serviceCategoryChanged:(id)sender;

@property (weak) IBOutlet id<AMCServiceSelectorViewControllerDelegate>delegate;

@property (weak) IBOutlet NSTableView *servicesTable;

@end
