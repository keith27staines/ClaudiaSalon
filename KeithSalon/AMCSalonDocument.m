//
//  AMCSalonDocument.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCSalonDocument.h"
#import "AMCStorePopulator.h"
#import "AMCReportsViewController.h"
#import "AMCAppointmentsViewController.h"
#import "AMCSalesViewController.h"
#import "AMCPaymentsViewController.h"
#import "AMCStockControlViewController.h"
#import "AMCAssociatedNotesViewController.h"
#import "AMCMoneyTransferViewController.h"
#import "AMCAccountReconciliationViewController.h"
#import "AMCStaffBusyViewController.h"
#import "AMCStaffCanDoViewController.h"
#import "AMCRequestPasswordWindowController.h"
#import "AMCSalaryPaymentViewController.h"
#import "AMCManagersBudgetWindowController.h"
#import "AMCDayAndMonthPopupViewController.h"
#import "AMCStaffCanDoViewController.h"
#import "AMCAccountStatementViewController.h"
#import "AMCCategoryManagerViewController.h"
#import "AMCCustomersViewController.h"
#import "AMCServicesViewController.h"
#import "AMCServiceCategoriesViewController.h"
#import "AMCServiceCategoriesNode.h"
#import "AMCEmployeesViewController.h"

#import "EditObjectViewController.h"

// Data models
#import "Salon+Methods.h"
#import "Account+Methods.h"
#import "AccountReconciliation+Methods.h"
#import "Customer+Methods.h"
#import "EditObjectViewController.h"
#import "EditObjectViewControllerDelegate.h"
#import "Employee+Methods.h"
#import "Payment+Methods.h"
#import "NSDate+AMCDate.h"
#import "Service+Methods.h"
#import "ServiceCategory+Methods.h"
#import "Salary+Methods.h"
#import "WorkRecord+Methods.h"
#import "AMCSalonDetailsViewController.h"
#import "RecurringItem+Methods.h"

static NSString * const kAMCDataStoreDirectory = @"kAMCDataStoreDirectory";

@interface AMCSalonDocument() <NSTabViewDelegate, NSTableViewDelegate,AMCDayAndMonthPopupViewControllerDelegate, NSControlTextEditingDelegate, NSAnimationDelegate, EditObjectViewControllerDelegate>
{
    BOOL _storeNeedsInitializing;
    Salon * _salon;
    OpeningHoursWeekTemplate * _openingHoursWeekTemplate;
}

@property (weak) IBOutlet AMCRequestPasswordWindowController *requestPasswordWindowController;
@property (weak) IBOutlet AMCManagersBudgetWindowController *managersBudgetWindowController;
@property (weak) IBOutlet AMCSalaryPaymentViewController *salaryPaymentViewController;
@property (weak) IBOutlet AMCStaffBusyViewController *staffBusyViewController;
@property (weak) IBOutlet AMCStaffCanDoViewController *staffCanDoViewController;

@property (weak) IBOutlet AMCAccountStatementViewController *accountStatementViewController;
@property (strong) IBOutlet AMCCategoryManagerViewController *accountGroupingsViewController;

@property (strong) IBOutlet AMCSalonDetailsViewController *salonDetailsViewController;

@property (strong) IBOutlet AMCViewController *recurringEventManagementViewController;

@property (strong) IBOutlet AMCViewController *accountManagementViewController;

@property (weak) IBOutlet NSButton *showPaySalary;

@property AMCViewController * mainViewController;


@property NSViewAnimation * notesUpAnimation;
@property NSViewAnimation * notesDownAnimation;
@property NSRect notesButtonInitialRect;
@property NSURL * dataStoreDirectory;

@end

@implementation AMCSalonDocument
- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}
-(void)processRecurringEvents:(id)sender {
    [RecurringItem processOutstandingItemsFor:self.managedObjectContext error:nil];
}
-(Salon *)salon {
    if (!_salon) {
        _salon = [Salon salonWithMoc:self.managedObjectContext];
        [self processRecurringEvents:self];
        [NSTimer scheduledTimerWithTimeInterval:3600 target:self selector:@selector(processRecurringEvents:) userInfo:nil repeats:YES];
    }
    return _salon;
}
-(Customer *)anonymousCustomer {
    if (!self.salon.anonymousCustomer) {
        self.salon.anonymousCustomer = [Customer newObjectWithMoc:self.managedObjectContext];
        self.salon.anonymousCustomer.firstName = @"Anonymous";
        self.salon.anonymousCustomer.lastName = @"Customer";
        self.salon.anonymousCustomer.phone = @"00000000000";
    }
    return self.salon.anonymousCustomer;
}
- (BOOL)configurePersistentStoreCoordinatorForURL:(NSURL *)url ofType:(NSString *)fileType modelConfiguration:(NSString *)configuration storeOptions:(NSDictionary *)storeOptions error:(NSError **)error
{
    NSMutableDictionary *newStoreOptions;
    if (storeOptions == nil) {
        newStoreOptions = [NSMutableDictionary dictionary];
    }
    else {
        newStoreOptions = [storeOptions mutableCopy];
    }
    NSDictionary *pragmaOptions = @{@"journal_mode":@"DELETE"};
    newStoreOptions[NSMigratePersistentStoresAutomaticallyOption] = @YES;
    newStoreOptions[NSInferMappingModelAutomaticallyOption] = @YES;
    newStoreOptions[NSSQLitePragmasOption] = pragmaOptions;
                    
    [newStoreOptions setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
    
    BOOL result = [super configurePersistentStoreCoordinatorForURL:url ofType:fileType modelConfiguration:configuration storeOptions:newStoreOptions error:error];
    [self salon];
    return result;
}
- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    self.requestPasswordWindowController.document = self;
    self.managersBudgetWindowController.document = self;
    self.mainViewController = [AMCViewController new];
    self.mainViewController.view = self.windowForSheet.contentView;
    [self.customerTable setSortDescriptors:[self initialSortDescriptorsForCustomersTable]];
    [self.employeesTable setSortDescriptors:[self initialSortDescriptorsForEmployeesTable]];
    [self.topTabView selectFirstTabViewItem:self];
    [self tabView:self.topTabView didSelectTabViewItem:self.topTabView.selectedTabViewItem];
}
+ (BOOL)autosavesInPlace {
    return YES;
}
- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"AMCSalonDocument";
}
-(NSArray*)initialSortDescriptorsForSalesTable
{
    return @[[NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:NO]];
}
-(NSArray*)initialSortDescriptorsForEmployeesTable
{
    return @[[NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES],
                 [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES]];
}
-(NSArray*)initialSortDescriptorsForServiceCategoriesTable
{
    return @[[NSSortDescriptor sortDescriptorWithKey:@"categoryName" ascending:YES]];
}
-(NSArray*)initialSortDescriptorsForCustomersTable
{
    return @[[NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES] ,
             [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
             [NSSortDescriptor sortDescriptorWithKey:@"phone" ascending:YES],
             [NSSortDescriptor sortDescriptorWithKey:@"lastVisitDate" ascending:NO]];
}
#pragma mark - Actions to create new objects
-(IBAction)createCustomerButtonClicked:(id)sender
{
    Customer * customer = [self newCustomer];
    customer.firstName = self.firstNameFilter.stringValue;
    customer.lastName = self.lastNameFilter.stringValue;
    customer.email = self.emailAddressFilter.stringValue;
    customer.phone = self.phoneFilter.stringValue;
    [self editObject:customer inMode:EditModeCreate withViewController:self.editCustomerViewController];
}
-(IBAction)createEmployeeButtonClicked:(id)sender
{
    Employee * employee = [self newEmployee];
    [self editObject:employee inMode:EditModeCreate withViewController:self.editEmployeeViewController];
}
#pragma mark - Object creation methods
-(Customer*)newCustomer
{
    Customer * customer = [Customer newObjectWithMoc:self.managedObjectContext];
    [self.customerArrayController addObject:customer];
    [self.customerArrayController rearrangeObjects];
    [self selectCustomer:customer];
    return customer;
}
-(Employee*)newEmployee
{
    Employee * employee = [Employee newObjectWithMoc:self.managedObjectContext];
    [self.employeeArrayController addObject:employee];
    [self.employeeArrayController rearrangeObjects];
    [self selectEmployee:employee];
    return employee;
}
#pragma mark - Obtain selected object methods
-(Employee*)selectedEmployee
{
    NSArray * array = self.employeeArrayController.arrangedObjects;
    NSUInteger index = self.employeesTable.selectedRowIndexes.firstIndex;
    if (index == NSNotFound) {
        return nil;
    }
    return array[index];
}
-(Customer*)selectedCustomer
{
    NSArray * array = self.customerArrayController.arrangedObjects;
    NSUInteger index = self.customerTable.selectedRowIndexes.firstIndex;
    if (index == NSNotFound) {
        return nil;
    }
    return array[index];
}
#pragma mark - Select specified object methods
-(void)selectCustomer:(Customer*)customer
{
    NSArray * array = [self.customerArrayController arrangedObjects];
    NSUInteger index = [array indexOfObject:customer];
    [self.customerTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self animateNotesButtonIfNecessaryForSelectedTab];
}
-(void)selectEmployee:(Employee*)employee
{
    NSArray * array = [self.employeeArrayController arrangedObjects];
    NSUInteger index = [array indexOfObject:employee];
    [self.employeesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [self animateNotesButtonIfNecessaryForSelectedTab];
}

#pragma mark - View selected object detail methods
-(IBAction)viewCustomerButtonClicked:(id)sender
{
    Customer * customer = [self selectedCustomer];
    [self editObject:customer inMode:EditModeView withViewController:self.editCustomerViewController];
}
-(IBAction)viewEmployeeButtonClicked:(id)sender
{
    Employee * employee = [self selectedEmployee];
    [self editObject:employee inMode:EditModeView withViewController:self.editEmployeeViewController];
}
#pragma mark - NSTabViewDelegate
-(void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSView * container = tabViewItem.view;
    if ([tabViewItem.identifier isEqualToString:@"reports"]) {
        // Reports tab
        [self safelyAddContentFromViewController:self.reportsViewController toContainerView:container];
   } else if ([tabViewItem.identifier isEqualToString:@"appointments"]) {
       // appointments tab
        [self safelyAddContentFromViewController:self.appointmentsViewController toContainerView:container];
    } else if ([tabViewItem.identifier isEqualToString:@"payments"]) {
        // Payments tab
        [self safelyAddContentFromViewController:self.paymentsViewController toContainerView:container];
    } else if ([tabViewItem.identifier isEqualToString:@"stock"]) {
        // Stock tab
        [self safelyAddContentFromViewController:self.stockViewController toContainerView:container];
    } else if ([tabViewItem.identifier isEqualToString:@"sales"]) {
        // Sales tab
        [self safelyAddContentFromViewController:self.salesViewController toContainerView:container];
    } else if ([tabViewItem.identifier isEqualToString:@"staff2"]) {
        // Staff2
        [self safelyAddContentFromViewController:self.employeesViewController toContainerView:container];
    } else if ([tabViewItem.identifier isEqualToString:@"customers2"]) {
        // Customers2
        [self safelyAddContentFromViewController:self.customersViewController toContainerView:container];
    } else if ([tabViewItem.identifier isEqualToString:@"services"]) {
        // Services tab
        [self safelyAddContentFromViewController:self.servicesViewController toContainerView:container];
    } else if ([tabViewItem.identifier isEqualToString:@"serviceCategories"]) {
        // Service categories tab
        [self safelyAddContentFromViewController:self.serviceCategoriesViewController toContainerView:container];
    } else {
        // All other tabs are already loaded
        [self enableViewItemButtonForTableViews];
    }
}
-(void)safelyAddContentFromViewController:(AMCViewController*)viewController toContainerView:(NSView*)container  {
    // Only add if not already added
    if ([container subviews].count == 0) {
        [viewController prepareForDisplayWithSalon:self];
        NSView * view = viewController.view;
        [view setTranslatesAutoresizingMaskIntoConstraints:NO];
        [container addSubview:view];
        NSDictionary * views = NSDictionaryOfVariableBindings(view);
        NSArray * constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[view]-|" options:0 metrics:nil views:views];
        [container addConstraints:constraints];
        constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[view]-|" options:0 metrics:nil views:views];
        [container addConstraints:constraints];
    } else {
        [viewController prepareForDisplayWithSalon:self];
    }
}

#pragma mark - AMCDayAndMonthPopupControllerDelegate
-(void)dayAndMonthControllerDidUpdate:(AMCDayAndMonthPopupViewController *)dayAndMonthController
{
    if (dayAndMonthController == self.birthdayPopupFilter) {
        [self reloadCustomersTable];
    }
}
#pragma mark - editObjectViewControllerDelegate
-(void)editObjectViewController:(EditObjectViewController *)controller didCancelCreationOfObject:(id)object {
    [self ensureDeletionAfterCancellationOfCreatedObject:object];
}
-(void)editObjectViewController:(EditObjectViewController *)controller didCompleteCreationOfObject:(id)object {
    [self enableViewItemButtonForTableViews];
}
-(void)editObjectViewController:(EditObjectViewController *)controller didEditObject:(id)object {
}
-(void)ensureDeletionAfterCancellationOfCreatedObject:(id)object {
    if (object) {
        [self.managedObjectContext deleteObject:object];
    }
}
#pragma mark - NSControlTextEditingDelegate
-(void)controlTextDidChange:(NSNotification *)notification
{
    if (notification.object == self.firstNameFilter) {
        self.firstNameFilter.stringValue = [self.firstNameFilter.stringValue capitalizedString];
    }
    if (notification.object == self.lastNameFilter) {
        self.lastNameFilter.stringValue = [self.lastNameFilter.stringValue capitalizedString];
    }
    [self reloadCustomersTable];
}
#pragma mark - Customer tab filters
- (IBAction)clearCustomerFilters:(id)sender {
    [self clearCustomersFilterSet];
    [self reloadCustomersTable];
}
-(void)reloadCustomersTable
{
    [self.customerArrayController setFilterPredicate:[self buildPredicateFromCustomerFilters]];
    [self.customerTable reloadData];
}
-(NSSet*)customersFilterSet
{
    return [NSSet setWithObjects:
            self.firstNameFilter,
            self.lastNameFilter,
            self.phoneFilter,
            self.emailAddressFilter,
            self.birthdayPopupFilter ,nil];
}
-(void)clearCustomersFilterSet
{
    self.firstNameFilter.stringValue = @"";
    self.lastNameFilter.stringValue = @"";
    self.phoneFilter.stringValue = @"";
    self.emailAddressFilter.stringValue = @"";
    [self.birthdayPopupFilter selectMonthNumber:0 dayNumber:0];
}
-(NSPredicate*)buildPredicateFromCustomerFilters
{
    NSMutableArray * predicateArray = [NSMutableArray array];
    // First Name
    if (self.firstNameFilter.stringValue.length > 0) {
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"firstName beginswith[cd] %@",self.firstNameFilter.stringValue]];
    }
    // Last Name
    if (self.lastNameFilter.stringValue.length > 0) {
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"lastName beginswith[cd] %@",self.lastNameFilter.stringValue]];
    }
    // email
    if (self.emailAddressFilter.stringValue.length > 0) {
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"email beginswith[cd] %@",self.emailAddressFilter.stringValue]];
    }
    // phone
    if (self.phoneFilter.stringValue.length > 0) {
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"phone beginswith[cd] %@",self.phoneFilter.stringValue]];
    }
    // day of birth
    if (self.birthdayPopupFilter.dayNumber > 0) {
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"dayOfBirth = %@",@(self.birthdayPopupFilter.dayNumber)]];
    }
    // month of birth
    if (self.birthdayPopupFilter.monthNumber > 0) {
        [predicateArray addObject:[NSPredicate predicateWithFormat:@"monthOfBirth = %@",@(self.birthdayPopupFilter.monthNumber)]];
    }
    return [NSCompoundPredicate andPredicateWithSubpredicates:predicateArray];
}
#pragma mark - Helpers
-(void)enableViewItemButtonForTableViews
{
    [self.viewEmployeeButton setEnabled:(self.employeesTable.selectedRow >= 0)?YES:NO];
    [self.viewCustomerButton setEnabled:(self.customerTable.selectedRow>=0)?YES:NO];
}

- (IBAction)showCustomerNotesButtonClicked:(id)sender {
    Customer * customer = [self selectedCustomer];
    [self showNotesPopoverForObject:customer forButton:sender];
}
-(IBAction)showEmployeeNotesButtonClicked:(id)sender {
    Employee * employee = [self selectedEmployee];
    [self showNotesPopoverForObject:employee forButton:sender];
}
-(IBAction)showNotesPopoverForObject:(id)objectWithNotes forButton:(NSButton*)button {
    AMCAssociatedNotesViewController*vc = [AMCAssociatedNotesViewController new];
    vc.objectWithNotes = objectWithNotes;
    [vc prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewController:vc asPopoverRelativeToRect:button.bounds ofView:button preferredEdge:NSMinYEdge behavior:NSPopoverBehaviorTransient];
}

-(void)animateNotesButtonIfNecessaryForSelectedTab {
    if ([self.topTabView.selectedTabViewItem.identifier isEqualToString:@"appointments"]) {
        return;
    }
    if ([self.topTabView.selectedTabViewItem.identifier isEqualToString:@"customers"]) {
        [self animateNotesButton:self.showCustomerNotesButton ifNecessaryForObject:[self selectedCustomer]];
        return;
    }
    if ([self.topTabView.selectedTabViewItem.identifier isEqualToString:@"staff"]) {
        [self animateNotesButton:self.showEmployeeNotesButton ifNecessaryForObject:[self selectedEmployee]];
        return;
    }
    if ([self.topTabView.selectedTabViewItem.identifier isEqualToString:@"reports"]) {
        return;
    }
}
-(void)animateNotesButton:(NSButton*)button ifNecessaryForObject:(id<AMCObjectWithNotesProtocol>)selectedObject {
    if (selectedObject && selectedObject.nonAuditNotes.count > 0) {
        [self animateNotesButton:button];
    }
}
-(void)animateNotesButton:(NSButton*)button {
    NSRect notesViewFrame;
    self.notesButtonInitialRect = button.frame;
    NSRect newViewFrame;
    NSMutableDictionary* notesViewDict;
    
    // Create the attributes dictionary for the notes view
    notesViewDict = [NSMutableDictionary dictionaryWithCapacity:3];
    notesViewFrame = [button frame];
    
    // Specify which view to modify.
    [notesViewDict setObject:button forKey:NSViewAnimationTargetKey];
    
    // Specify the starting position of the view.
    [notesViewDict setObject:[NSValue valueWithRect:notesViewFrame]
                      forKey:NSViewAnimationStartFrameKey];
    
    // Change the ending position of the view.
    newViewFrame = notesViewFrame;
    newViewFrame.origin.y += 25;
    [notesViewDict setObject:[NSValue valueWithRect:newViewFrame]
                      forKey:NSViewAnimationEndFrameKey];
    
    // Create the view animation object.
    NSViewAnimation *theAnim;
    theAnim = [[NSViewAnimation alloc] initWithViewAnimations:@[notesViewDict]];
    
    // Set some additional attributes for the animation.
    [theAnim setDuration:0.5];    // One and a half seconds.
    [theAnim setAnimationCurve:NSAnimationEaseInOut];
    [theAnim setAnimationBlockingMode:NSAnimationNonblocking];
    [theAnim setDelegate:self];
    self.notesUpAnimation = theAnim;
    
    [notesViewDict setObject:[NSValue valueWithRect:newViewFrame]
                      forKey:NSViewAnimationStartFrameKey];
    [notesViewDict setObject:[NSValue valueWithRect:notesViewFrame]
                      forKey:NSViewAnimationEndFrameKey];
    theAnim = [[NSViewAnimation alloc] initWithViewAnimations:@[notesViewDict]];
    
    // Set some additional attributes for the animation.
    [theAnim setDuration:0.5];    // half second.
    [theAnim setAnimationCurve:NSAnimationEaseInOut];
    [theAnim setAnimationBlockingMode:NSAnimationNonblocking];
    [theAnim setDelegate:self];
    self.notesDownAnimation = theAnim;
    
    // Run the animation.
    [self.notesUpAnimation startAnimation];
}
#pragma mark - NSAnimationDelegate
-(void)animation:(NSAnimation *)animation didReachProgressMark:(NSAnimationProgress)progress {
    if (animation == self.notesUpAnimation && progress == 1) {
        [self.notesDownAnimation startAnimation];
    }
}
-(void)editObject:(id)object inMode:(EditMode)editMode withViewController:(EditObjectViewController*)viewController
{
    NSAssert(object, @"No object to edit");
    if (object) {
        viewController.delegate = self;
        viewController.editMode = editMode;
        [viewController clear];
        viewController.objectToEdit = object;
        [viewController prepareForDisplayWithSalon:self];
        [self.mainViewController presentViewControllerAsSheet:viewController];
    }
}
#pragma mark - NSTableViewDelegate
-(void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self enableViewItemButtonForTableViews];
    [self animateNotesButtonIfNecessaryForSelectedTab];
}
-(BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}
- (IBAction)salonToolbarButton:(id)sender {
    NSButton * button = sender;
    NSDate * date = [NSDate date];
    AMCStaffBusyViewController*vc = self.staffBusyViewController;
    vc.startDate = [date beginningOfDay];
    [vc.endDate =date endOfDay];
    [vc prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewController:vc asPopoverRelativeToRect:button.bounds ofView:button preferredEdge:NSMaxYEdge behavior:NSPopoverBehaviorTransient];
}
- (IBAction)showMoneyInTill:(id)sender {
    NSButton * button = sender;
    self.requestPasswordWindowController.callingWindow = self.windowForSheet;
    NSWindow * window = [self.requestPasswordWindowController window];
    [self.windowForSheet beginSheet:window completionHandler:^(NSModalResponse returnCode) {
        if ([self.requestPasswordWindowController.state isEqualToString:@"ok"]) {
            AMCAccountReconciliationViewController*vc = [AMCAccountReconciliationViewController new];
            vc.account = self.salon.tillAccount;
            [vc prepareForDisplayWithSalon:self];
            [self.mainViewController presentViewController:vc asPopoverRelativeToRect:button.bounds ofView:button preferredEdge:NSMaxYEdge behavior:NSPopoverBehaviorTransient];
        }
    }];
}
- (IBAction)showCanDoListButtonClicked:(id)sender {
    NSButton * button = sender;
    [self.staffCanDoViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewController:self.staffCanDoViewController asPopoverRelativeToRect:button.bounds ofView:button preferredEdge:NSMinYEdge behavior:NSPopoverBehaviorTransient];
}

- (IBAction)paySalaries:(id)sender {
    [self.salaryPaymentViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.salaryPaymentViewController];
}
- (IBAction)showManagersBudget:(id)sender {
    NSWindow * sheet = self.managersBudgetWindowController.window;
    [self.managersBudgetWindowController reloadData];
    sheet.parentWindow = self.windowForSheet ;
    [self.windowForSheet beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
       // Nothing to do yet
    }];
}
- (IBAction)showBankStatements:(id)sender {
    [self.accountStatementViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.accountStatementViewController];
}

- (IBAction)manageAccountancyGroupings:(id)sender {
    [self.accountGroupingsViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.accountGroupingsViewController];
}
-(IBAction)showSalonDetails:(id)sender {
    self.salonDetailsViewController.salonProperties = self.salon;
    [self.salonDetailsViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.salonDetailsViewController];
}
- (IBAction)showRecurringEventManager:(id)sender {
    [self.recurringEventManagementViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.recurringEventManagementViewController];
}
- (IBAction)showAccountManager:(id)sender {
    [self.accountManagementViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.accountManagementViewController];
}


@end
