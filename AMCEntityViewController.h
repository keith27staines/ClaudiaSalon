//
//  AMCEntityViewController.h
//  
//
//  Created by Keith Staines on 23/11/2014.
//
//

#import <Cocoa/Cocoa.h>
#import "AMCSalonDocument.h"
#import "EditObjectViewController.h"

@interface AMCEntityViewController : AMCViewController <NSTableViewDataSource, NSTableViewDelegate, EditObjectViewControllerDelegate>


- (void)editObject:(id)object  forSalon:(AMCSalonDocument*)salon inMode:(EditMode)editMode withViewController: (EditObjectViewController*)windowController;

@property (weak) IBOutlet EditObjectViewController * editObjectViewController;
@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSTableView *dataTable;
@property (readonly) id selectedObject;
@property id objectSelectedBeforeEditorInvoked;

-(NSString *)nibName;
- (NSString*)entityName;
-(void)applySearchField;

@property NSArray * displayedObjects;

@property NSArray * filteredObjects;
@property (readonly) NSPredicate * filtersPredicate;

@property (weak) IBOutlet NSButton *viewDetailsButton;

@end
