//
//  AMCCategoryManagementViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 19/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCCategoryManagementViewController.h"
#import "AMCSalonDocument.h"
#import "PaymentCategory+Methods.h"
#import "AMCCategoriesRootNode.h"
#import "EditObjectViewController.h"

#import "AMCCashBookNode.h"

#define rowDragAndDropType @"rowDragAndDropType"

@interface AMCCategoryManagementViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate,NSMenuDelegate>
{

}
@property (weak) IBOutlet NSButton *addButton;
@property (weak) IBOutlet NSButton *removeButton;
@property (weak) IBOutlet NSOutlineView *treeView;

@property (weak) IBOutlet NSTextField *titleLabel;
@property (strong) IBOutlet NSMenu *addMenu;
@property (strong) IBOutlet NSMenu *rightClickMenu;
@end

typedef NS_ENUM(NSInteger, MenuButtonTags) {
    MenuButtonTagsAddNode = 0,
    MenuButtonTagsAddLeaf = 1,
    MenuButtonTagsEdit = 2,
};

@implementation AMCCategoryManagementViewController

-(NSString *)nibName {
    return @"AMCCategoryManagementViewController";
}
#pragma mark - Methods to override
-(NSString *)title {
    return @"Manage Tree";
    // ; @"Manage Accounting and Groups and Payment Categories";
}
-(NSString *)titleForAddleafAction {
    return @"Add Leaf";
}
-(NSString *)titleForAddNodeAction {
    return @"Add Node";
}
-(AMCTreeNode *)makeChildLeafForParent:(AMCTreeNode *)node {
    return nil;
}
-(AMCTreeNode *)makeChildNodeForParent:(AMCTreeNode *)node {
    return nil;
}
-(EditObjectViewController *)editViewControllerForNode:(AMCTreeNode *)node {
    return nil;
}
-(BOOL)canAddNodeToNode:(AMCTreeNode *)node {
    if (!node) return NO;
    return YES;
}
-(BOOL)canRemoveNode:(AMCTreeNode *)node {
    if (!node || node.isSystemNode || node.isLeaf) return NO;
    return YES;
}
#pragma mark - NSView
-(void)viewDidLoad {
    [self.treeView registerForDraggedTypes:@[rowDragAndDropType]];
    [self.treeView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
    [self.treeView setDoubleAction:@selector(doubleClick:)];
    self.addButton.menu.delegate = self;
}
#pragma mark - AMCViewController
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    self.titleLabel.stringValue = self.title;
    [self.treeView reloadData];
    [self outlineViewSelectionDidChange:nil];
}
#pragma mark - Actions
- (IBAction)rightClickAddLeaf:(id)sender {
    [self addLeafToRow:self.treeView.clickedRow];
}
- (IBAction)rightClickAddNode:(id)sender {
    [self addNodeToRow:self.treeView.clickedRow];
}
-(IBAction)addLeaf:(id)sender {
    [self addLeafToRow:self.treeView.selectedRow];
}
-(IBAction)addNode:(id)sender {
    [self addNodeToRow:self.treeView.selectedRow];
}
-(IBAction)rightClickEdit:(id)sender {
    [self editRow:self.treeView.clickedRow];
}
-(IBAction)edit:(id)sender {
    [self editRow:self.treeView.selectedRow];
}
-(void)dismissViewController:(NSViewController *)viewController {
    [super dismissViewController:viewController];
}
- (IBAction)doubleClick:(id)sender {
    [self editRow:self.treeView.clickedRow];
}

- (IBAction)addButtonClicked:(id)sender {
    [self.addButton.menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(self.addButton.frame.origin.x,self.addButton.frame.origin.y - 10) inView:self.view];
}
- (IBAction)removeButtonClicked:(id)sender {
    NSInteger row = self.treeView.selectedRow;
    AMCTreeNode * item = [self.treeView itemAtRow:row];
    if (!item) return;
    if (item.isLeaf) return;
    [self moveContentOfCategory:item toCategory:[item mostRecentAncestralDefault]];
    [item.parentNode removeChild:item];
    [self.treeView reloadData];
}
- (IBAction)doneButtonClicked:(id)sender {
    [self dismissController:self];
}
- (IBAction)nodeNameChanged:(id)sender {
    NSTextField * textField = sender;
    NSInteger row = [self.treeView rowForView:sender];
    AMCTreeNode * node = [self.treeView itemAtRow:row];
    node.name = textField.stringValue;
}
#pragma mark - Add object implementation
-(AMCTreeNode*)addNodeToRow:(NSInteger)row {
    AMCTreeNode * parentNode = [self parentForRow:row];
    if (!parentNode) return nil;
    AMCTreeNode * newNode = [self makeChildNodeForParent:parentNode];
    [self makeVisibleAndSelect:newNode];
    return newNode;
}
-(AMCTreeNode*)addLeafToRow:(NSInteger)row {
    AMCTreeNode * parentNode = [self parentForRow:row];
    if (!parentNode) return nil;
    AMCTreeNode * newNode = [self makeChildLeafForParent:parentNode];
    [self makeVisibleAndSelect:newNode];
    return newNode;
}
#pragma mark - Move object implementation
-(BOOL)shouldMove:(AMCTreeNode*)moving toParent:(AMCTreeNode*)proposedParent {
    if ([proposedParent hasAncestor:moving]) {
        return NO;
    }
    return !proposedParent.isLeaf;
}
-(BOOL)move:(AMCTreeNode*)moving toParent:(AMCTreeNode*)newParent {
    if (newParent.isLeaf) {
        newParent = newParent.parentNode;
    }
    if (!newParent) newParent = [moving mostRecentAncestralDefault];
    if (![self shouldMove:moving toParent:newParent]) {
        return NO;
    }
    [moving.parentNode removeChild:moving];
    [newParent addChild:moving];
    [self.treeView expandItem:newParent];
    return YES;
}
-(void)moveContentOfCategory:(AMCTreeNode*)sourceCategory toCategory:(AMCTreeNode*)destinationCategory {
    if (sourceCategory == destinationCategory) {
        return;
    }
    for (AMCTreeNode * item in sourceCategory.allChildren) {
        [sourceCategory removeChild:item];
        [destinationCategory addChild:item];
    }
}
#pragma mark - NSOutlineView
-(BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (![item isKindOfClass:[AMCTreeNode class]]) {
        return NO;
    }
    AMCTreeNode * node = item;
    if (!node) return NO;
    if (node.isLeaf) return NO;
    return (node.count>0)?YES:NO;
}
-(NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    AMCTreeNode * node = item;
    if (!node) {
        node = self.rootNode;
    }
    return node.count;
}
-outlineView:(NSOutlineView*)outlineView child:(NSInteger)index ofItem:(id)item {
    AMCTreeNode * node = item;
    if (!node) {
        node = self.rootNode;
    }
    if (node.isLeaf) return nil;

    if (index < node.nodesCount) {
        return [node nodeAtIndex:index];
    } else {
        return [node leafAtIndex:index - node.nodesCount];
    }
}
-(NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView * view;
    AMCTreeNode * node = item;
    if (node) {
        if (node.isLeaf) {
            view = [self.treeView makeViewWithIdentifier:@"leafView" owner:self];
            view.textField.editable = NO;
        } else {
            view = [self.treeView makeViewWithIdentifier:@"nodeView" owner:self];
            view.textField.editable = YES;
        }
        view.textField.stringValue = (node.name)?node.name:@"New";
    }
    return view;
}
-(BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return NO;
}

-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    if (item) {
        NSPasteboard * pboard = [info draggingPasteboard];
        NSData * data = [pboard dataForType:rowDragAndDropType];
        NSIndexSet * rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSInteger row = [rowIndexes firstIndex];
        AMCTreeNode * node = [self.treeView itemAtRow:row];
        if (![self shouldMove:node toParent:item]) {
            return NSDragOperationNone;
        }
    }
    return NSDragOperationMove;
}
-(BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id<NSDraggingInfo>)info item:(id)item childIndex:(NSInteger)index {
    if (item) {
        NSPasteboard * pboard = [info draggingPasteboard];
        NSData * data = [pboard dataForType:rowDragAndDropType];
        NSIndexSet * rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSMutableArray * movers = [NSMutableArray array];
        NSUInteger currentIndex = [rowIndexes firstIndex];
        while (currentIndex != NSNotFound)
        {
            [movers addObject:[self.treeView itemAtRow:currentIndex]];
            currentIndex = [rowIndexes indexGreaterThanIndex: currentIndex];
        }
        for (AMCTreeNode * node in movers) {
            [self move:node toParent:item];
        }
        [self.treeView reloadData];
        [self.treeView expandItem:item];
        [self makeVisibleAndSelect:item];
        return YES;
    }
    return NO;
}
-(void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.treeView.selectedRow;
    AMCTreeNode * selectedNode = [self.treeView itemAtRow:row];
    self.addButton.enabled= NO;
    self.removeButton.enabled = NO;
    if ([self canAddNodeToNode:selectedNode]) {
        self.addButton.enabled = YES;
    }
    if ([self canRemoveNode:selectedNode]) {
        self.removeButton.enabled = YES;
    }
}
-(NSArray*)topLevelObjectsInSelection {
    return nil;
}
-(BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
    NSMutableIndexSet * rowIndexes = [NSMutableIndexSet indexSet];
    for (AMCTreeNode * item in items) {
        AMCTreeNode * node = (AMCTreeNode*)item;
        if (!node.isSystemNode) {
            NSInteger row = [self.treeView rowForItem:item];
            [rowIndexes addIndex:row];
        }
    }
    if (rowIndexes.count > 0) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
        [pasteboard declareTypes:[NSArray arrayWithObject:rowDragAndDropType] owner:self];
        [pasteboard setData:data forType:rowDragAndDropType];
        return YES;
    }
    return NO;
}
#pragma mark - NSMenuDelegate
-(void)menuNeedsUpdate:(NSMenu *)menu {
    [menu itemWithTag:0].title = self.titleForAddNodeAction;
    [menu itemWithTag:1].title = self.titleForAddleafAction;
}
#pragma mark - Convenience methods
-(void)makeVisibleAndSelect:(AMCTreeNode*)node {
    if (!node) return;
    [self.treeView reloadData];
    [self.treeView expandItem:node.parentNode];
    NSInteger row = [self.treeView rowForItem:node];
    [self.treeView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [self.treeView scrollRowToVisible:row];
}
-(AMCTreeNode*)parentForRow:(NSInteger)row {
    if (row < 0) return nil;
    AMCTreeNode *parentNode = [self.treeView itemAtRow:row];
    if (parentNode.isLeaf) {
        parentNode = parentNode.parentNode;
    }
    return parentNode;
}
-(void)editRow:(NSInteger)row {
    if (row < 0) return;
    AMCTreeNode * nodeToEdit = [self.treeView itemAtRow:row];
    EditObjectViewController * editor = [self editViewControllerForNode:nodeToEdit];
    if (!editor) return;
    editor.editMode = EditModeView;
    [editor prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:editor];
}

@end
