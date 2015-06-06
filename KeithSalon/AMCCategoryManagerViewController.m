//
//  AMCCategoryManagerViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 19/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCCategoryManagerViewController.h"
#import "PaymentCategory+Methods.h"
#import "ServiceCategory+Methods.h"
#import "AMCCategoriesRootNode.h"
#define rowDragAndDropType @"rowDragAndDropType"

@interface AMCCategoryManagerViewController () <NSOutlineViewDataSource, NSOutlineViewDelegate>
{
    NSMutableArray * _allPaymentCategoryLeaves;
    NSMutableArray * _allServiceCategoryLeaves;
    NSMutableDictionary * _systemCategories;
}
@property (weak) IBOutlet NSButton *addButton;
@property (weak) IBOutlet NSButton *removeButton;
@property (weak) IBOutlet NSOutlineView *categoriesOutlineView;
@property AMCTreeNode * rootNode;

@end

@implementation AMCCategoryManagerViewController

-(NSString *)nibName {
    return @"AMCCategoryManagerViewController";
}
-(void)viewDidLoad {
    [self.categoriesOutlineView registerForDraggedTypes:@[rowDragAndDropType]];
    [self.categoriesOutlineView setDraggingSourceOperationMask:NSDragOperationMove forLocal:YES];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self readFromUserDefaults];
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
            AMCTreeNode * leaf = [[AMCTreeNode alloc] initWithName:category.categoryName isLeaf:YES];
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
- (IBAction)resetToDefaults:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kAMCSystemCategories];
    [self readFromUserDefaults];
    [self.categoriesOutlineView reloadData];
}
- (IBAction)addButtonClicked:(id)sender {
    AMCTreeNode * newCategory = [[AMCTreeNode alloc] initWithName:@"New Category" isLeaf:NO];
    newCategory.isDeletable = YES;
    NSInteger row = self.categoriesOutlineView.selectedRow;
    AMCTreeNode * parent = nil;
    if (row >= 0) {
        AMCTreeNode * item = [self.categoriesOutlineView itemAtRow:row];
        if (item.isLeaf) {
            parent = item.parentNode;
            if (parent) {
                [parent addChild:newCategory];
            } else {
                [self.rootNode addChild:newCategory];
            }
        } else {
            parent = item;
            [parent addChild:newCategory];
        }
    } else {
        [self.rootNode addChild:newCategory];
    }
    [self.categoriesOutlineView reloadData];
    if (parent) {
        [self.categoriesOutlineView expandItem:parent];
        row = [self.categoriesOutlineView rowForItem:newCategory];
        [self.categoriesOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row]byExtendingSelection:NO];
    }
    [self saveToUserDefaults];
}
- (void)moveCategoryContentToDefault:(AMCTreeNode *)category {
    [self moveContentOfCategory:category toCategory:[category mostRecentAncestralDefault]];
}
-(BOOL)shouldMoveCategory:(AMCTreeNode*)mover toCategory:(AMCTreeNode*)newParent {
    return [self.rootNode shouldMoveChild:mover toNewParent:newParent];
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
    if (!item.isDeletable) return;
    if (item.isLeaf) return;
    [self moveContentOfCategory:item toCategory:[item mostRecentAncestralDefault]];
    [item.parentNode removeChild:item];
    [self saveToUserDefaults];
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
    [self saveToUserDefaults];
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
            view = [self.categoriesOutlineView makeViewWithIdentifier:@"leafView" owner:self];
            view.textField.editable = NO;
        } else {
            view = [self.categoriesOutlineView makeViewWithIdentifier:@"nodeView" owner:self];
            view.textField.editable = YES;
        }
        view.textField.stringValue = node.name;
    }
    return view;
}
-(BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    AMCTreeNode * node = item;
    if (node.isLeaf) {
        return NO;
    } else {
        return YES;
    }
}
-(void)outlineView:(NSOutlineView *)outlineView updateDraggingItemsForDrag:(id<NSDraggingInfo>)draggingInfo {
    
}
-(NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id<NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
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
    [self saveToUserDefaults];
    [self.categoriesOutlineView reloadData];
    return YES;
}
-(NSArray*)topLevelObjectsInSelection {
    return nil;
}
-(BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pasteboard {
    NSMutableIndexSet * rowIndexes = [NSMutableIndexSet indexSet];
    for (AMCTreeNode * item in items) {
        if (item.isLeaf) {
            NSInteger row = [self.categoriesOutlineView rowForItem:item];
            [rowIndexes addIndex:row];
        }
    }
    if (rowIndexes.count > 0) {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
        [pasteboard declareTypes:[NSArray arrayWithObject:rowDragAndDropType] owner:self];
        [pasteboard setData:data forType:rowDragAndDropType];
    }
    return YES;
}

@end
