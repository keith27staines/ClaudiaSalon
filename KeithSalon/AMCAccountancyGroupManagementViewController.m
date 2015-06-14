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
#import "AMCCashBookNode.h"

@interface AMCAccountancyGroupManagementViewController ()
{
    AMCTreeNode * _rootNode;

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
        _rootNode = [[AMCCashBookNode alloc] initWithSalon:self.salonDocument.salon];
    }
    return _rootNode;
}
-(BOOL)canAddNodeToNode:(AMCTreeNode *)node {
    return [super canAddNodeToNode:node];
}
-(BOOL)canRemoveNode:(AMCTreeNode *)node {
    if (![super canRemoveNode:node] || node.isSystemNode || node.isLeaf) return NO;
    return YES;
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
    return nil;
}
@end

