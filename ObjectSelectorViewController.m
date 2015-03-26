//
//  ObjectSelectorViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 23/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "ObjectSelectorViewController.h"

@interface ObjectSelectorViewController ()
{
    __weak id _selectedObject;
    NSArray * _objects;
}
@property (weak,readwrite) id selectedObject;

@end

@implementation ObjectSelectorViewController


-(void)cancel:(id)sender
{
    _isCancelled = YES;
    [self.presentingViewController dismissController:self];
}
-(void)selectObject:(id)sender
{
    _isCancelled = NO;
    [self.presentingViewController dismissController:self];
    self.selectedObject = self.objects[self.objectTable.selectedRow];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.objects.count;
}
-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self.selectButton setEnabled:YES];
}
@end
