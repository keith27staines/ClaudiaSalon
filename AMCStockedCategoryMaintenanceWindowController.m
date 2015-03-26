//
//  AMCStockedCategoryMaintenanceWindowController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 02/01/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCStockedCategoryMaintenanceWindowController.h"

@interface AMCStockedCategoryMaintenanceWindowController ()

@end

@implementation AMCStockedCategoryMaintenanceWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}
-(NSString *)windowNibName {
    return @"AMCStockedCategoryMaintenanceWindowController";
}
-(NSManagedObjectContext *)moc {
    return self.documentMoc;
}
-(void)dismissController:(id)sender {
    id responder = [self.window firstResponder];
    [self.window makeFirstResponder:nil];
    if (self.window.firstResponder == responder) {
        [self.window endEditingFor:nil];
    }
    [self.window orderOut:self];
    [self.sourceWindow endSheet:self.window returnCode:NSModalResponseStop];
}
@end
