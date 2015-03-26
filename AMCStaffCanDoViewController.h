//
//  AMCStaffCanDoViewController.h
//  ClaudiasSalon
//
//  Created by service on 24/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCStaffCanDoViewController : AMCViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (weak) IBOutlet NSTableView *canDoTableView;
- (IBAction)canDoButtonChanged:(NSButton *)sender;

@end
