//
//  AMCStockedBrandMaintenanceWindowController.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 03/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCStockedBrandMaintenanceWindowController : NSWindowController

@property (weak) NSWindow * sourceWindow;
@property (weak,readonly) NSManagedObjectContext * moc;
@end
