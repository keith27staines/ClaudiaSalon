//
//  AMCCategoryManagementViewController.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 19/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
@class EditObjectViewController;

#import <Cocoa/Cocoa.h>
#import "AMCViewController.h"
#import "AMCTreeNode.h"

@interface AMCCategoryManagementViewController : AMCViewController

// Override these (might have to call super)
-(BOOL)shouldMove:(AMCTreeNode*)moving toParent:(AMCTreeNode*)proposedParent;
-(void)menuNeedsUpdate:(NSMenu *)menu;
-(AMCTreeNode*)makeChildLeafForParent:(AMCTreeNode*)node;
-(AMCTreeNode*)makeChildNodeForParent:(AMCTreeNode*)node;
@property (readonly) AMCTreeNode * rootNode;
@property (readonly) NSString * titleForAddNodeAction;
@property (readonly) NSString * titleForAddleafAction;
-(EditObjectViewController*)editViewControllerForNode:(AMCTreeNode*)node;
-(BOOL)canAddNodeToNode:(AMCTreeNode*)node;
-(BOOL)canAddLeafToNode:(AMCTreeNode*)node;
-(BOOL)canRemoveNode:(AMCTreeNode*)node;
-(void)deleteNode:(AMCTreeNode*)node;
-(void)moveContentOfNode:(AMCTreeNode*)sourceNode toNode:(AMCTreeNode*)destinationNode;
@property (weak) IBOutlet NSOutlineView *treeView;
@end
