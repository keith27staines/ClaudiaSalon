//
//  AMCServiceTableCellViewMac.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 12/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AMCServiceTableCellViewMac : NSTableCellView


@property (weak) IBOutlet NSTextField *serviceName;
@property (weak) IBOutlet NSTextField *price;

@end
