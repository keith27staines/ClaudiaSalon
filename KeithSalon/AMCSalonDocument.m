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
#import "AMCCustomersViewController.h"
#import "AMCPaymentsViewController.h"
#import "AMCServicesViewController.h"
#import "AMCServiceCategoriesViewController.h"
#import "AMCEmployeesViewController.h"
#import "AMCStockControlViewController.h"

#import "AMCAccountReconciliationViewController.h"
#import "AMCStaffBusyViewController.h"
#import "AMCRequestPasswordWindowController.h"
#import "AMCSalaryPaymentViewController.h"
#import "AMCManagersBudgetWindowController.h"
#import "AMCAccountStatementViewController.h"
#import "AMCCategoryManagerViewController.h"
#import "AMCFinancialAnalysisViewController.h"

#import "Salon+Methods.h"
#import "Customer+Methods.h"
#import "NSDate+AMCDate.h"
#import "AMCSalonDetailsViewController.h"
#import "RecurringItem+Methods.h"

// Imports required for data fixes
#import "ServiceCategory+Methods.h"
// End imports for data fixes

static NSString * const kAMCDataStoreDirectory = @"kAMCDataStoreDirectory";

@interface AMCSalonDocument() <NSTabViewDelegate>
{
    BOOL _storeNeedsInitializing;
    Salon * _salon;
    OpeningHoursWeekTemplate * _openingHoursWeekTemplate;
}

@property (weak) IBOutlet AMCRequestPasswordWindowController *requestPasswordWindowController;
@property (weak) IBOutlet AMCManagersBudgetWindowController *managersBudgetWindowController;
@property (weak) IBOutlet AMCSalaryPaymentViewController *salaryPaymentViewController;
@property (weak) IBOutlet AMCStaffBusyViewController *staffBusyViewController;
@property (weak) IBOutlet AMCAccountStatementViewController *accountStatementViewController;
@property (strong) IBOutlet AMCCategoryManagerViewController *accountGroupingsViewController;
@property (strong) IBOutlet AMCSalonDetailsViewController *salonDetailsViewController;
@property (strong) IBOutlet AMCViewController *recurringEventManagementViewController;
@property (strong) IBOutlet AMCViewController *accountManagementViewController;
@property (weak) IBOutlet NSButton *showPaySalary;
@property AMCViewController * mainViewController;

@property (strong) IBOutlet AMCFinancialAnalysisViewController *financialAnalysisViewController;

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
        [self dataFixes];
        [self processRecurringEvents:self];
        [NSTimer scheduledTimerWithTimeInterval:3600 target:self selector:@selector(processRecurringEvents:) userInfo:nil repeats:YES];
    }
    return _salon;
}
-(void)dataFixes {
    // Begin Service category data fix
    ServiceCategory * rootServiceCategory = _salon.rootServiceCategory;
    if (!rootServiceCategory) {
        rootServiceCategory   = [ServiceCategory newObjectWithMoc:self.managedObjectContext];
        _salon.rootServiceCategory = rootServiceCategory;
        ServiceCategory * hairCategory = [ServiceCategory newObjectWithMoc:self.managedObjectContext];
        ServiceCategory * beautyCategory = [ServiceCategory newObjectWithMoc:self.managedObjectContext];

        rootServiceCategory.name   = @"Service Categories";
        hairCategory.name   = @"Hair";
        beautyCategory.name = @"Beauty";
        rootServiceCategory.isSystemCategory = @YES;
        hairCategory.isSystemCategory = @YES;
        beautyCategory.isSystemCategory = @YES;
        rootServiceCategory.isDefaultCategory = @YES;
        hairCategory.isDefaultCategory = @YES;
        beautyCategory.isDefaultCategory = @YES;
        [rootServiceCategory addSubCategoriesObject:hairCategory];
        [rootServiceCategory addSubCategoriesObject:beautyCategory];
        for (ServiceCategory * category in [ServiceCategory allObjectsWithMoc:self.managedObjectContext]) {
            if (!category.parent && category != rootServiceCategory) {
                if ([category isHairCategory]) {
                    category.parent = hairCategory;
                } else {
                    category.parent = beautyCategory;
                }
                category.salon = _salon;
            }
        }
    } // End Service Category data fix
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
    } else if ([tabViewItem.identifier isEqualToString:@"staff"]) {
        // Staff
        [self safelyAddContentFromViewController:self.employeesViewController toContainerView:container];
    } else if ([tabViewItem.identifier isEqualToString:@"customers"]) {
        // Customers
        [self safelyAddContentFromViewController:self.customersViewController toContainerView:container];
    } else if ([tabViewItem.identifier isEqualToString:@"services"]) {
        // Services tab
        [self safelyAddContentFromViewController:self.servicesViewController toContainerView:container];
    } else if ([tabViewItem.identifier isEqualToString:@"serviceCategories"]) {
        // Service categories tab
        [self safelyAddContentFromViewController:self.serviceCategoriesViewController toContainerView:container];
    } else {
        // All other tabs are already loaded
        NSAssert(NO, @"Unexpected tab - no corresponding view to display");
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
- (IBAction)salonToolbarButton:(id)sender {
    NSDate * date = [NSDate date];
    AMCStaffBusyViewController*vc = self.staffBusyViewController;
    vc.startDate = [date beginningOfDay];
    [vc.endDate =date endOfDay];
    [vc prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:vc];
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
- (IBAction)paySalaries:(id)sender {
    [self.salaryPaymentViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.salaryPaymentViewController];
}
- (IBAction)showManagersBudget:(id)sender {
    NSWindow * sheet = self.managersBudgetWindowController.window;
    self.managersBudgetWindowController.callingWindow = self.windowForSheet;
    [self.managersBudgetWindowController reloadData];
    [self.windowForSheet beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
       // Nothing to do yet
    }];
}
- (IBAction)showBankStatements:(id)sender {
    [self.accountStatementViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.accountStatementViewController];
}
- (IBAction)manageCashbookGroups:(id)sender {
    self.accountGroupingsViewController.categoryType = AMCCategoryTypePayments;
    [self.accountGroupingsViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.accountGroupingsViewController];
}
- (IBAction)manageServices:(id)sender {
    self.accountGroupingsViewController.categoryType = AMCCategoryTypeServices;
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
- (IBAction)showFinancialAnalysis:(id)sender {
    [self.financialAnalysisViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.financialAnalysisViewController];
}

@end
