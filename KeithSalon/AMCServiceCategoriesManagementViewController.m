//
//  AMCServiceCategoriesManagementViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 13/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCServiceCategoriesManagementViewController.h"
#import "ServiceCategory+Methods.h"
#import "Service+Methods.h"
#import "EditServiceCategoryViewController.h"
#import "EditServiceViewController.h"

@interface AMCServiceCategoriesManagementViewController ()
{
    AMCTreeNode * _rootNode;
    EditServiceCategoryViewController * _editServiceCategoryViewController;
    EditServiceViewController * _editServiceViewController;
}
@property (readonly) EditServiceViewController * editServiceViewController;
@property (readonly) EditServiceCategoryViewController * editServiceCategoryViewController;
@end

@implementation AMCServiceCategoriesManagementViewController
-(NSString *)title {
    return @"Manage Services and Service Categories";
}
-(NSString *)titleForAddleafAction {
    return @"Add Service";
}
-(NSString *)titleForAddNodeAction {
    return @"Add Service Category";
}
-(BOOL)canAddNodeToNode:(AMCTreeNode *)node {
    return [super canAddNodeToNode:node];
}
-(BOOL)canRemoveNode:(AMCTreeNode *)node {
    return [super canRemoveNode:node];
}
-(AMCTreeNode*)rootNode {
    if (!_rootNode) {
        id<AMCTreeNode>root = (id<AMCTreeNode>)self.salonDocument.salon.rootServiceCategory;
        _rootNode = [[AMCTreeNode alloc] initWithRepresentedObject:root];
    }
    return _rootNode;
}
-(AMCTreeNode *)makeChildLeafForParent:(AMCTreeNode *)parentNode {
    NSAssert(parentNode, @"Parent cannot be nil");
    NSAssert(!parentNode.isLeaf, @"Parent cannot be a leafNode");
    AMCTreeNode * newLeaf = nil;
    if (!parentNode) return nil;
    if (parentNode.isLeaf) return nil;
    id<AMCTreeNode> representedObject = nil;
    representedObject = [ServiceCategory newObjectWithMoc:self.documentMoc];
    representedObject.name = @"New Service";
    newLeaf = [[AMCTreeNode alloc] initWithRepresentedObject:representedObject];
    [parentNode addChild:newLeaf];
    return newLeaf;
}
-(AMCTreeNode *)makeChildNodeForParent:(AMCTreeNode *)parentNode {
    NSAssert(parentNode, @"Parent cannot be nil");
    NSAssert(!parentNode.isLeaf, @"Parent cannot be a leafNode");
    AMCTreeNode * newNode = nil;
    if (!parentNode) return nil;
    if (parentNode.isLeaf) return nil;
    id<AMCTreeNode> representedObject = nil;
    representedObject = [Service newObjectWithMoc:self.documentMoc];
    representedObject.name = @"New Service Category";
    newNode = [[AMCTreeNode alloc] initWithRepresentedObject:representedObject];
    [parentNode addChild:newNode];
    return newNode;
}
-(EditObjectViewController *)editViewControllerForNode:(AMCTreeNode*)nodeToEdit {
    if (nodeToEdit.isLeaf) {
        self.editServiceViewController.objectToEdit = nodeToEdit.representedObject;
        return self.editServiceViewController;
    } else {
        self.editServiceCategoryViewController.objectToEdit = nodeToEdit.representedObject;
        return self.editServiceCategoryViewController;
    }
}
-(EditServiceViewController *)editServiceViewController {
    if (!_editServiceViewController) {
        _editServiceViewController = [[EditServiceViewController alloc] init];
    }
    return _editServiceViewController;
}
-(EditServiceCategoryViewController *)editServiceCategoryViewController {
    if (!_editServiceCategoryViewController) {
        _editServiceCategoryViewController = [[EditServiceCategoryViewController alloc] init];
    }
    return _editServiceCategoryViewController;
}
@end
