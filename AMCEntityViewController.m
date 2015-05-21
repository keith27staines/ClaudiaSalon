//
//  AMCEntityViewController.m
//  
//
//  Created by Keith Staines on 23/11/2014.
//
//

#import "AMCEntityViewController.h"
#import "NSDate+AMCDate.h"
#import "EditObjectViewController.h"
#import "AMCSalonDocument.h"

@implementation AMCEntityViewController

-(void)editObject:(id)object forSalon:(AMCSalonDocument*)salon inMode:(EditMode)editMode withViewController:(EditObjectViewController*)viewController
{
    if (object) {
        viewController.salonDocument = salon;
        viewController.delegate = self;
        viewController.editMode = editMode;
        [viewController clear];
        viewController.objectToEdit = object;
        [viewController prepareForDisplayWithSalon:self.salonDocument];
        [self presentViewControllerAsSheet:viewController];
    }
}
- (IBAction)viewDetailsClicked:(id)sender {
    self.objectSelectedBeforeEditorInvoked = self.selectedObject;
    [self editObject:self.selectedObject forSalon:self.salonDocument inMode:EditModeView withViewController:[self editObjectViewController]];
}
- (IBAction)searchFieldChanged:(id)sender {
    [self applySearchField];
    [self.dataTable reloadData];
}
-(NSString *)nibName {
    [NSException raise:@"Must override" format:@"This method must be overridden in subclasses"];
    return @"";
}
- (NSString*)entityName {
    [NSException raise:@"Must override" format:@"This method must be overridden in subclasses"];
    return @"";
}

-(id)selectedObject {
    NSInteger selectedRow = self.dataTable.selectedRow;
    if (selectedRow >= 0 ) {
        return self.displayedObjects[selectedRow];
    }
    return nil;
}

-(void)applySearchField {

}
-(void)prepareForDisplay {
    [self reloadData];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    if (self.dataTable.selectedRow >= 0) {
        [self.dataTable scrollRowToVisible:self.dataTable.selectedRow];
    }
}
-(void)reloadData {
    NSManagedObjectContext * moc = self.salonDocument.managedObjectContext;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[self filtersPredicate]];
    NSError *error = nil;
    self.filteredObjects = [[moc executeFetchRequest:fetchRequest error:&error] mutableCopy];
    if (self.filteredObjects == nil) {
        self.filteredObjects = [NSMutableArray array];
    }
    self.filteredObjects = [self.filteredObjects sortedArrayUsingDescriptors:self.dataTable.sortDescriptors];
    [self applySearchField];
    [self.dataTable reloadData];
    if (self.objectSelectedBeforeEditorInvoked) {
        NSInteger index = [self.displayedObjects indexOfObject:self.objectSelectedBeforeEditorInvoked];
        if (index != NSNotFound) {
            NSIndexSet * set = [NSIndexSet indexSetWithIndex:index];
            [self.dataTable selectRowIndexes:set byExtendingSelection:NO];
            [self.dataTable scrollRowToVisible:index];
        }
    }
    if (self.dataTable.selectedRow >=0) {
        [self.dataTable scrollRowToVisible:self.dataTable.selectedRow];
    }
}
#pragma mark - NSTableViewDataSource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.dataTable) {
        return self.displayedObjects.count;
    }
    return 0;
}
#pragma mark - NSTableViewDelegate
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    return NO;
}
- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    self.displayedObjects = [self.displayedObjects sortedArrayUsingDescriptors: [tableView sortDescriptors]];
    [tableView reloadData];
}
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    [NSException raise:@"Must override" format:@"This method must be overridden in subclasses"];
    return nil;
}

#pragma mark - editObjectViewControllerDelegate
-(void)editObjectViewController:(EditObjectViewController *)controller didCancelCreationOfObject:(id)cancelledObject {
    NSManagedObjectContext * moc = self.salonDocument.managedObjectContext;
    if (cancelledObject) {
        [moc deleteObject:cancelledObject];
    }
    [self reloadData];
}
#pragma mark - EditObjectViewControllerDelegate
-(void)editObjectViewController:(EditObjectViewController *)controller didEditObject:(id)object {
    [self reloadData];
}
-(void)editObjectViewController:(EditObjectViewController *)controller didCompleteCreationOfObject:(id)createdObject {
    self.objectSelectedBeforeEditorInvoked = createdObject;
    [self reloadData];
}
@end
