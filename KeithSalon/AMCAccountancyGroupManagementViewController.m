//
//  AMCAccountancyGroupManagementViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 13/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCAccountancyGroupManagementViewController.h"
#import "PaymentCategory+Methods.h"
#import "AccountingPaymentGroup+Methods.h"
#import "AMCCashBookRootNode.h"
#import "EditPaymentCategoryViewController.h"
#import "EditAccountancyGroupViewController.h"

@interface AMCAccountancyGroupManagementViewController ()
{
    AMCTreeNode * _rootNode;
    EditPaymentCategoryViewController * _editPaymentCategoryViewController;
    EditAccountancyGroupViewController * _editAccountingGroupViewController;
}
@end

@implementation AMCAccountancyGroupManagementViewController
-(NSString *)title {
    return @"Manage Accountancy Groups and Payment Categories";
}
-(NSString *)titleForAddleafAction {
    return @"Add Payment Category";
}
-(NSString *)titleForAddNodeAction {
    return @"Add Accountancy Group";
}
-(AMCTreeNode*)rootNode {
    if (!_rootNode) {
        _rootNode = [[AMCCashBookRootNode alloc] initWithSalon:self.salonDocument.salon];
    }
    return _rootNode;
}
-(BOOL)canAddNodeToNode:(AMCTreeNode *)node {
    AMCCashBookRootNode * root = (AMCCashBookRootNode*)self.rootNode;
    if (node == root.expenditureRoot || node == root.incomeRoot) {
        return YES;
    }
    return NO;
}
-(BOOL)canAddLeafToNode:(AMCTreeNode *)node {
    AMCCashBookRootNode * root = (AMCCashBookRootNode*)self.rootNode;
    if (node.parentNode == root.expenditureRoot || node.parentNode == root.incomeRoot) {
        return YES;
    }
    return NO;
}
-(BOOL)canRemoveNode:(AMCTreeNode *)node {
    if (![super canRemoveNode:node] || node.isSystemNode || node.isLeaf) return NO;
    return YES;
}
-(void)deleteNode:(AMCTreeNode*)node {
    if (!node) return;
    if (node.isLeaf) return;
    AMCCashBookRootNode * root = (AMCCashBookRootNode*)_rootNode;
    AMCCashBookNode * cashbookNode = (AMCCashBookNode*)node;
    if (cashbookNode.isExpenditure) {
        [self moveContentOfNode:node toNode:root.expenditureOtherNode];
    } else {
        [self moveContentOfNode:node toNode:root.incomeOtherNode];
    }
    [node.parentNode removeChild:node];
    [self.treeView reloadData];
}
-(AMCTreeNode *)makeChildLeafForParent:(AMCTreeNode *)parentNode {
    NSAssert(parentNode, @"Parent cannot be nil");
    NSAssert(!parentNode.isLeaf, @"Parent cannot be a leafNode");
    AMCCashBookNode * newLeaf = nil;
    if (!parentNode) return nil;
    if (parentNode.isLeaf) return nil;
    PaymentCategory * paymentCategory = [PaymentCategory newObjectWithMoc:self.documentMoc];
    paymentCategory.categoryName = @"New Payment Category";
    newLeaf = [[AMCCashBookNode alloc] initWithPaymentCategory:paymentCategory];
    [parentNode addChild:newLeaf];
    return newLeaf;
}
-(AMCTreeNode *)makeChildNodeForParent:(AMCTreeNode *)parentNode {
    NSAssert(parentNode, @"Parent cannot be nil");
    NSAssert(!parentNode.isLeaf, @"Parent cannot be a leafNode");
    AMCCashBookNode * newNode = nil;
    if (!parentNode) return nil;
    if (parentNode.isLeaf) return nil;
    id<AMCTreeNode> representedObject = nil;
    representedObject = [AccountingPaymentGroup newObjectWithMoc:self.documentMoc];
    representedObject.name = @"New Accounting Group";
    newNode = [[AMCCashBookNode alloc] initWithAccountancyGroup:representedObject];
    [parentNode addChild:newNode];
    return newNode;
}
-(EditObjectViewController *)editViewControllerForNode:(AMCTreeNode*)nodeToEdit {
    EditObjectViewController * editor = nil;
    if (nodeToEdit.isLeaf) {
        if (!_editPaymentCategoryViewController) {
            _editPaymentCategoryViewController = [[EditPaymentCategoryViewController alloc] init];
        }
        editor = _editPaymentCategoryViewController;
        editor.objectToEdit = ((AMCCashBookNode*)nodeToEdit).paymentCategory;
    } else {
        if (!_editAccountingGroupViewController) {
            _editAccountingGroupViewController = [[EditAccountancyGroupViewController alloc] init];
        }
        editor = _editAccountingGroupViewController;
        editor.objectToEdit = nodeToEdit.representedObject;
    }
    return editor;
}
#pragma mark - Move object implementation
-(BOOL)shouldMove:(AMCTreeNode*)moving toParent:(AMCTreeNode*)proposedParent {
    if (![super shouldMove:moving toParent:proposedParent]) {
        return NO;
    }
    
    // Can't move from expenditure categories to income categories or vice-versa
    AMCCashBookNode * movingCashNode = (AMCCashBookNode*)moving;
    AMCCashBookNode * proposedParentCashNode = (AMCCashBookNode*)proposedParent;
    if (movingCashNode.isExpenditure != proposedParentCashNode.isExpenditure &&
        movingCashNode.isIncome != proposedParentCashNode.isIncome) {
        return NO;
    }
    if (moving.isLeaf) {
        return [self canAddLeafToNode:proposedParent];
    } else {
        return [self canAddNodeToNode:proposedParent];
    }
}
@end

