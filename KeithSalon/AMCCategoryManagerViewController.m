//
//  AMCCategoryManagerViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 19/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCCategoryManagerViewController.h"
#import "AMCSalonDocument.h"
#import "PaymentCategory+Methods.h"
#import "Service+Methods.h"
#import "ServiceCategory+Methods.h"
#import "AMCCategoriesRootNode.h"
#import "AMCTreeNode.h"
#import "EditServiceCategoryViewController.h"
#import "EditServiceViewController.h"
#import "AMCCashBookNode.h"

#define rowDragAndDropType @"rowDragAndDropType"

@interface AMCCategoryManagerViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate,NSMenuDelegate>
{
    NSMutableArray * _allPaymentCategoryLeaves;
    NSMutableArray * _allServiceCategoryLeaves;
    NSMutableDictionary * _systemCategories;
}
@property (weak) IBOutlet NSButton *addButton;
@property (weak) IBOutlet NSButton *removeButton;
@property (weak) IBOutlet NSOutlineView *categoriesOutlineView;
@property AMCTreeNode * rootNode;
@property AMCTreeNode * viewRootNode;
@property (weak) IBOutlet NSTextField *titleLabel;
@property (strong) IBOutlet NSMenu *addMenu;
@property (strong) IBOutlet NSMenu *rightClickMenu;
@property (weak) IBOutlet NSMenuItem *addObjectMenuItem;
@property (weak) IBOutlet NSMenuItem *addCategoryMenuItem;
@property (strong) IBOutlet EditServiceCategoryViewController *editServiceCategoryViewController;

@property (strong) IBOutlet EditServiceViewController *editServiceViewController;
@property (weak) EditObjectViewController * editViewController;
@end

@implementation AMCCategoryManagerViewController

-(NSString *)nibName {
    return @"AMCCategoryManagerViewController";
}
-(void)viewDidLoad {
    [self.categoriesOutlineView registerForDraggedTypes:@[rowDragAndDropType]];
    [self.categoriesOutlineView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
    [self.categoriesOutlineView setDoubleAction:@selector(doubleClick:)];
    self.addButton.menu.delegate = self;
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    switch (self.categoryType) {
        case AMCCategoryTypeServices:
        {
            self.titleLabel.stringValue = @"Manage Services and Service Categories";
            id<AMCTreeNode>root = (id<AMCTreeNode>)self.salonDocument.salon.rootServiceCategory;
            self.rootNode = [[AMCTreeNode alloc] initWithRepresentedObject:root];
            self.viewRootNode = self.rootNode;
            break;
        }
        case AMCCategoryTypePayments:
        {
            self.titleLabel.stringValue = @"Manage Accounting and Payment Categories";
            self.rootNode = [[AMCCashBookNode alloc] initWithSalon:self.salonDocument.salon];
            self.viewRootNode = self.rootNode;
            break;
        }
    }
    [self.categoriesOutlineView reloadData];
}
-(NSMutableArray *)allServiceCategoryLeaves {
    if (!_allServiceCategoryLeaves) {
        _allServiceCategoryLeaves = [NSMutableArray array];
        NSArray * allCategories = [ServiceCategory allObjectsWithMoc:self.documentMoc];
        for (ServiceCategory * category in allCategories) {
            AMCTreeNode * leaf = [[AMCTreeNode alloc] initWithName:category.name isLeaf:YES];
            [_allServiceCategoryLeaves addObject:leaf];
        }
    }
    return [_allServiceCategoryLeaves copy];
}
-(NSMutableArray *)allPaymentCategoryLeaves {
    if (!_allPaymentCategoryLeaves) {
        _allPaymentCategoryLeaves = [NSMutableArray array];
        NSArray * allCategories = [PaymentCategory allObjectsWithMoc:self.documentMoc];
        for (PaymentCategory * category in allCategories) {
            AMCTreeNode* leaf = [[AMCTreeNode alloc] initWithName:category.categoryName isLeaf:YES];
            [_allPaymentCategoryLeaves addObject:leaf];
        }
    }
    return [_allPaymentCategoryLeaves copy];
}
-(NSData*)dataForUserDefaultsRegistration {
    AMCCategoriesRootNode * root = [[AMCCategoriesRootNode alloc] init];
    return [NSKeyedArchiver archivedDataWithRootObject:root];
}
-(void)saveToUserDefaults {
    NSData * data = [NSKeyedArchiver archivedDataWithRootObject:self.rootNode];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:kAMCSystemCategories];
}
-(void)readFromUserDefaults {
    NSData * data = [[NSUserDefaults standardUserDefaults] dataForKey:kAMCSystemCategories];
    self.rootNode = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    self.rootNode.moc = self.documentMoc;
}
- (void)moveCategoryContentToDefault:(AMCTreeNode*)category {
    [self moveContentOfCategory:category toCategory:[category mostRecentAncestralDefault]];
}
-(void)makeVisibleAndSelect:(AMCTreeNode*)node {
    if (!node) return;
    [self.categoriesOutlineView reloadData];
    [self.categoriesOutlineView expandItem:node.parentNode];
    NSInteger row = [self.categoriesOutlineView rowForItem:node];
    [self.categoriesOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    [self.categoriesOutlineView scrollRowToVisible:row];
}
- (IBAction)rightClickAddObject:(id)sender {
    [self addObjectToRow:self.categoriesOutlineView.clickedRow];
}
- (IBAction)rightClickAddCategory:(id)sender {
    [self addCategoryToRow:self.categoriesOutlineView.clickedRow];
}
-(IBAction)addCategory:(id)sender {
    [self addCategoryToRow:self.categoriesOutlineView.selectedRow];
}
-(IBAction)addObject:(id)sender {
    [self addObjectToRow:self.categoriesOutlineView.selectedRow];
}
- (IBAction)rightClickEdit:(id)sender {
    [self editRow:self.categoriesOutlineView.clickedRow];
}
-(void)editRow:(NSInteger)row {
    if (row < 0) return;
    AMCTreeNode * nodeToEdit = [self.categoriesOutlineView itemAtRow:row];
    switch (self.categoryType) {
        case AMCCategoryTypePayments:
        {
            break;
        }
        case AMCCategoryTypeServices:
        {
            if (nodeToEdit.isLeaf) {
                self.editViewController = self.editServiceViewController;
            } else {
                self.editViewController = self.editServiceCategoryViewController;
            }
            break;
        }
    }
    self.editViewController.objectToEdit = nodeToEdit.representedObject;
    self.editViewController.editMode = EditModeView;
    [self.editViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.editViewController];
}
-(void)dismissViewController:(NSViewController *)viewController {
    [super dismissViewController:viewController];
}
- (IBAction)doubleClick:(id)sender {
    [self editRow:self.categoriesOutlineView.clickedRow];
}

- (IBAction)addButtonClicked:(id)sender {
    [self.addButton.menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(self.addButton.frame.origin.x,self.addButton.frame.origin.y - 10) inView:self.view];
}

-(AMCTreeNode*)addObjectToRow:(NSInteger)row {
    if (row < 0) return nil;
    AMCTreeNode * parentNode = [self.categoriesOutlineView itemAtRow:row];
    if (parentNode.isLeaf) {
        parentNode = parentNode.parentNode;
    }
    id<AMCTreeNode> representedObject = nil;
    AMCTreeNode * newNode = nil;
    switch (self.categoryType) {
        case AMCCategoryTypePayments:
        {
            return nil;
            break;
        }
        case AMCCategoryTypeServices:
        {
            representedObject = [Service newObjectWithMoc:self.documentMoc];
            representedObject.name = @"New Service";
            newNode = [[AMCTreeNode alloc] initWithRepresentedObject:representedObject];
            break;
        }
        default:
            return nil;
    }
    [parentNode addChild:newNode];
    [self makeVisibleAndSelect:newNode];
    return newNode;
}
-(AMCTreeNode*)addCategoryToRow:(NSInteger)row {
    if (row < 0) return nil;
    AMCTreeNode *parentNode = [self.categoriesOutlineView itemAtRow:row];
    if (parentNode.isLeaf) {
        parentNode = parentNode.parentNode;
    }
    id<AMCTreeNode> representedObject = nil;
    AMCTreeNode * newNode = nil;
    switch (self.categoryType) {
        case AMCCategoryTypePayments:
        {
            return nil;
            break;
        }
        case AMCCategoryTypeServices:
        {
            representedObject = [ServiceCategory newObjectWithMoc:self.documentMoc];
            representedObject.name = @"New Service Category";
            newNode = [[AMCTreeNode alloc] initWithRepresentedObject:representedObject];
            break;
        }
        default:
            return nil;
    }
    [parentNode addChild:newNode];
    [self makeVisibleAndSelect:newNode];
    return newNode;
}
-(AMCTreeNode*)addToTreeNode:(AMCTreeNode*)parent {
    id<AMCTreeNode> representedObject = nil;
    AMCTreeNode * newNode = nil;
    if ([parent.representedObject isKindOfClass:[ServiceCategory class]]) {
        representedObject = [ServiceCategory newObjectWithMoc:self.documentMoc];
        newNode = [[AMCTreeNode alloc] initWithRepresentedObject:representedObject];
    }
    if ([parent.representedObject isKindOfClass:[Service class]]) {
        representedObject = [Service newObjectWithMoc:self.documentMoc];
        newNode = [[AMCTreeNode alloc] initWithRepresentedObject:representedObject];
    }
    if (representedObject) {
        [parent addChild:newNode];
    }
    return newNode;
}
-(BOOL)shouldMoveCategory:(AMCTreeNode*)mover toCategory:(AMCTreeNode*)proposedParent {
    if ([proposedParent hasAncestor:mover]) {
        return NO;
    }
    return !proposedParent.isLeaf;
}
-(BOOL)moveCategory:(AMCTreeNode*)mover toCategory:(AMCTreeNode*)newParent {
    if (newParent.isLeaf) {
        newParent = newParent.parentNode;
    }
    if (!newParent) newParent = [mover mostRecentAncestralDefault];
    if (![self shouldMoveCategory:mover toCategory:newParent]) {
        return NO;
    }
    [mover.parentNode removeChild:mover];
    [newParent addChild:mover];
    [self.categoriesOutlineView expandItem:newParent];

    return YES;
}
-(void)moveContentOfCategory:(AMCTreeNode*)sourceCategory toCategory:(AMCTreeNode*)destinationCategory {
    if (sourceCategory == destinationCategory) {
        return;
    }
    if ([destinationCategory hasDescendent:sourceCategory]) {
        return;
    }
    for (AMCTreeNode * item in sourceCategory.allChildren) {
        [sourceCategory removeChild:item];
        [destinationCategory addChild:item];
    }
}
- (IBAction)removeButtonClicked:(id)sender {
    NSInteger row = self.categoriesOutlineView.selectedRow;
    AMCTreeNode * item = [self.categoriesOutlineView itemAtRow:row];
    if (!item) return;
    if (item.isLeaf) return;
    [self moveContentOfCategory:item toCategory:[item mostRecentAncestralDefault]];
    [item.parentNode removeChild:item];
    [self.categoriesOutlineView reloadData];
}
- (IBAction)doneButtonClicked:(id)sender {
    [self dismissController:self];
}
- (IBAction)nodeNameChanged:(id)sender {
    NSTextField * textField = sender;
    NSInteger row = [self.categoriesOutlineView rowForView:sender];
    AMCTreeNode * node = [self.categoriesOutlineView itemAtRow:row];
    node.name = textField.stringValue;
}
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
        node = self.viewRootNode;
    }
    return node.count;
}
-outlineView:(NSOutlineView*)outlineView child:(NSInteger)index ofItem:(id)item {
    AMCTreeNode * node = item;
    if (!node) {
        node = self.viewRootNode;
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
            view = [self.categoriesOutlineView makeViewWithIdentifier:@"leafView" owner:self];
            view.textField.editable = NO;
        } else {
            view = [self.categoriesOutlineView makeViewWithIdentifier:@"nodeView" owner:self];
            view.textField.editable = YES;
        }
        view.textField.stringValue = (node.name)?node.name:@"New";
    }
    return view;
}
-(BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return NO;
}
-(void)outlineView:(NSOutlineView *)outlineView updateDraggingItemsForDrag:(id<NSDraggingInfo>)draggingInfo {
    
}
-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    if (item) {
        NSPasteboard * pboard = [info draggingPasteboard];
        NSData * data = [pboard dataForType:rowDragAndDropType];
        NSIndexSet * rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        NSInteger row = [rowIndexes firstIndex];
        AMCTreeNode * node = [self.categoriesOutlineView itemAtRow:row];
        if (![self shouldMoveCategory:node toCategory:item]) {
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
        NSInteger row = [rowIndexes firstIndex];
        AMCTreeNode * node = [self.categoriesOutlineView itemAtRow:row];
        [self moveCategory:node toCategory:item];
    }
    [self.categoriesOutlineView reloadData];
    return YES;
}
-(NSArray*)topLevelObjectsInSelection {
    return nil;
}
-(BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
    NSMutableIndexSet * rowIndexes = [NSMutableIndexSet indexSet];
    for (AMCTreeNode * item in items) {
        NSInteger row = [self.categoriesOutlineView rowForItem:item];
        [rowIndexes addIndex:row];
    }
    if (rowIndexes.count > 0) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
        [pasteboard declareTypes:[NSArray arrayWithObject:rowDragAndDropType] owner:self];
        [pasteboard setData:data forType:rowDragAndDropType];
    }
    return YES;
}
#pragma mark - NSMenuDelegate
-(void)menuNeedsUpdate:(NSMenu *)menu {
    NSString * addNodeTitle = @"";
    NSString * addLeafTitle = @"";
    switch (self.categoryType) {
        case AMCCategoryTypePayments: {
            addNodeTitle = @"Add Accountancy Group";
            addLeafTitle = @"Add Payment Category";
            break;
        }
        case AMCCategoryTypeServices: {
            addNodeTitle = @"Add Service Category";
            addLeafTitle = @"Add Service";
            break;
        }
    }
    [menu itemWithTag:0].title = addNodeTitle;
    [menu itemWithTag:1].title = addLeafTitle;
}
#pragma mark - NSPopupButton

@end
