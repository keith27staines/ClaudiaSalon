//
//  AMCBookingViewController.h
//  ClaudiasSalon
//
//  Created by service on 19/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCBookingViewController : AMCViewController <NSTableViewDataSource, NSTableViewDelegate>
@property (copy) NSDate * date;
@property (weak) IBOutlet NSTextField *appontmentsForDateLabel;

@end
