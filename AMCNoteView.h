//
//  AMCNoteView.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCNoteView : NSTableCellView
@property (weak) IBOutlet NSTextField *titleField;
@property (weak) IBOutlet NSTextField *textField;

@end
