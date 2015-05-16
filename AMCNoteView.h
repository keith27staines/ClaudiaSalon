//
//  AMCNoteView.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 29/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class Note;
#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
@interface AMCNoteView : NSTableCellView

@property IBOutlet Note * note;
@property (weak) IBOutlet NSTextField *titleField;
@property (weak) IBOutlet NSTextField *dateField;
@property (weak, nonatomic) id target;
@property (assign, nonatomic) SEL removeAction;

@property BOOL isSelected;
@end
