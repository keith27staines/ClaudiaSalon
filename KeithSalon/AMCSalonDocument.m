//
//  AMCSalonDocument.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
#import <objc/runtime.h>
#import <IOKit/IOKitLib.h>
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
#import "AMCAccountancyGroupManagementViewController.h"
#import "AMCServiceCategoriesManagementViewController.h"
#import "AMCFinancialAnalysisViewController.h"

#import "Salon+Methods.h"
#import "Customer+Methods.h"
#import "NSDate+AMCDate.h"
#import "AMCSalonDetailsViewController.h"
#import "RecurringItem+Methods.h"
#import "AMCChangeUserViewController.h"
#import "AMCRoleManageViewController.h"

// Imports required for data fixes
#import "ServiceCategory+Methods.h"
#import "AccountingPaymentGroup+Methods.h"
#import "PaymentCategory+Methods.h"
#import "Employee+Methods.h"
#import "Role+Methods.h"
#import "RoleAction+Methods.h"
// End imports for data fixes

static NSString * const kAMCDataStoreDirectory = @"kAMCDataStoreDirectory";

@interface AMCSalonDocument() <NSTabViewDelegate,NSMenuDelegate>
{
    BOOL _storeNeedsInitializing;
    Salon * _salon;
    OpeningHoursWeekTemplate * _openingHoursWeekTemplate;
    Employee * _currentUser;
}

@property (weak) IBOutlet AMCRequestPasswordWindowController *requestPasswordWindowController;
@property (weak) IBOutlet AMCManagersBudgetWindowController *managersBudgetWindowController;
@property (weak) IBOutlet AMCSalaryPaymentViewController *salaryPaymentViewController;
@property (weak) IBOutlet AMCStaffBusyViewController *staffBusyViewController;
@property (weak) IBOutlet AMCAccountStatementViewController *accountStatementViewController;
@property (strong) IBOutlet AMCAccountancyGroupManagementViewController *accountGroupingsViewController;
@property (strong) IBOutlet AMCServiceCategoriesManagementViewController *serviceCategoryManagmentViewController;
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
@property (strong) IBOutlet AMCChangeUserViewController *changeUserViewController;

@property (strong) IBOutlet AMCRoleManageViewController *roleManager;
@property (weak) IBOutlet NSMenu *switchUserMenu;
@property (weak) IBOutlet NSMenuItem *titleItem;
@property (weak) IBOutlet NSMenuItem *logoutMenuItem;
@property (weak) IBOutlet NSMenuItem *switchUserMenuIem;
@property (weak) IBOutlet NSToolbarItem *toolbarUserPhotoItem;

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
    
    // Initialise entity "AccountancyPaymentGroup"
    [AccountingPaymentGroup buildDefaultGroupsForSalon:_salon];
    
    // Employees
    for (Employee * employee in [Employee allObjectsWithMoc:self.managedObjectContext]) {
        if (!employee.password || employee.password.length < 4) {
            employee.password = @"1234";
        }
        if (!employee.photo) {
            employee.photo = [[NSBundle mainBundle] imageForResource:@"UserIcon"];
        }
    }
    
    // Roles
    if ([Role allObjectsWithMoc:self.managedObjectContext].count == 0) {
        self.salon.systemRole       = [Role newObjectWithMoc:self.managedObjectContext];
        self.salon.systemAdminRole  = [Role newObjectWithMoc:self.managedObjectContext];
        self.salon.devSupportRole   = [Role newObjectWithMoc:self.managedObjectContext];
        self.salon.managerRole      = [Role newObjectWithMoc:self.managedObjectContext];
        self.salon.accountantRole   = [Role newObjectWithMoc:self.managedObjectContext];
        self.salon.receptionistRole = [Role newObjectWithMoc:self.managedObjectContext];
        self.salon.basicUserRole    = [Role newObjectWithMoc:self.managedObjectContext];
        self.salon.systemRole.name       = @"System";
        self.salon.systemAdminRole.name  = @"System Administrator";
        self.salon.devSupportRole.name   = @"Dev";
        self.salon.managerRole.name      = @"Manager";
        self.salon.accountantRole.name   = @"Accountant";
        self.salon.receptionistRole.name = @"Receptionist";
        self.salon.basicUserRole.name    = @"Basic User";
        self.salon.systemRole.fullDescription       = @"All-powerful role reserved for system-generated events. Do not give this role to any user";
        self.salon.systemAdminRole.fullDescription  = @"System Administrators need special permissions to configure the application";
        self.salon.devSupportRole.fullDescription   = @"Developers have access to special functions that allow them to investigate and debug problems";
        self.salon.managerRole.fullDescription      = @"Managers have access to all business functions but not technical functions";
        self.salon.accountantRole.fullDescription   = @"Accountants have access to financial functions but not to day-to-day business functions";
        self.salon.receptionistRole.fullDescription = @"Receptionists can take appointments and enter sales";
        self.salon.basicUserRole.fullDescription    = @"Basic Users can view appointments and sales";
        self.salon.systemRole.isSystemRole          = @YES;
        self.salon.systemAdminRole.isSystemRole     = @YES;
        self.salon.devSupportRole.isSystemRole      = @YES;
        self.salon.managerRole.isSystemRole         = @YES;
        self.salon.accountantRole.isSystemRole      = @YES;
        self.salon.receptionistRole.isSystemRole    = @YES;
        self.salon.basicUserRole.isSystemRole       = @YES;
        [self.salon.manager addRolesObject:self.salon.managerRole];
        [self.salon.manager addRolesObject:self.salon.receptionistRole];
        
        for (Employee * employee in [Employee allObjectsWithMoc:self.managedObjectContext]) {
            [employee addRolesObject:self.salon.basicUserRole];
        }
        [self.salon.manager addRolesObject:self.salon.basicUserRole];
    }
    NSArray * viewControllerClasses = subclasses([AMCViewController class]);
    RoleAction * viewAction = nil;
    RoleAction * editAction = nil;
    RoleAction * createAction = nil;
    RoleAction * deleteAction = nil;
    NSString * viewActionName = nil;

    for (Role * role in [Role allObjectsWithMoc:self.managedObjectContext]) {
        for (Class class in viewControllerClasses) {
            viewActionName = NSStringFromClass(class);
            viewAction = [RoleAction fetchActionWithName:viewActionName inMoc:self.managedObjectContext];
            if (viewAction) continue; // Already added this view action and its related edit/create/delete actions
          
            // add view action
            viewAction = [RoleAction newObjectWithMoc:self.managedObjectContext];
            viewAction.name = viewActionName;
            [role addAllowedActionsObject:viewAction];
            
            // add edit action
            editAction = [RoleAction newObjectWithMoc:self.managedObjectContext];
            editAction.name = [viewActionName stringByAppendingString:@"_Edit"];
            [role addAllowedActionsObject:editAction];
            
            // add create action
            createAction = [RoleAction newObjectWithMoc:self.managedObjectContext];
            createAction.name = [viewActionName stringByAppendingString:@"_Create"];
            [role addAllowedActionsObject:createAction];
            
            // add delete action
            deleteAction = [RoleAction newObjectWithMoc:self.managedObjectContext];
            deleteAction.name = [viewActionName stringByAppendingString:@"_Delete"];
            // Nobody gets delete permissions! [role addAllowedActionsObject:deleteAction];
        }
    }
    
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
    self.currentUser = nil;
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
    [self.accountGroupingsViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.accountGroupingsViewController];
}
- (IBAction)manageServices:(id)sender {
    [self.serviceCategoryManagmentViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.serviceCategoryManagmentViewController];
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
- (IBAction)switchUser:(id)sender {
    [self.changeUserViewController prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.changeUserViewController];
}
-(Employee *)currentUser {
    return _currentUser;
}
-(void)setCurrentUser:(Employee *)currentUser {
    _currentUser = currentUser;
    if (currentUser) {
        self.toolbarUserPhotoItem.image = currentUser.photo;
        self.titleItem.title = currentUser.firstName;
    } else {
        self.toolbarUserPhotoItem.image = [[NSBundle mainBundle] imageForResource:@"UserIcon"];
        self.titleItem.title = @"Default user";
    }
}
- (IBAction)logoutCurrentUser:(id)sender {
    self.currentUser = nil;
}
- (IBAction)manageRolesAndRoleActions:(id)sender {
    [self.roleManager prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.roleManager];
}
-(void)menuNeedsUpdate:(NSMenu *)menu {
    if (menu == self.switchUserMenu) {
        if (self.currentUser) {
            self.logoutMenuItem.enabled = YES;
            self.switchUserMenuIem.title = @"Switch user...";
        } else {
            self.logoutMenuItem.enabled = NO;
            self.switchUserMenuIem.title = @"Login...";
        }
        self.switchUserMenuIem.enabled = YES;
    }
}

NSArray *subclasses(Class parentClass)
{
    int numClasses = objc_getClassList(NULL, 0);
    Class *classes = NULL;
    
    classes = (__unsafe_unretained Class*)malloc(sizeof(Class) * numClasses);
    numClasses = objc_getClassList(classes, numClasses);
    
    NSMutableArray *result = [NSMutableArray array];
    for (NSInteger i = 0; i < numClasses; i++)
    {
        Class superClass = classes[i];
        do
        {
            superClass = class_getSuperclass(superClass);
        } while(superClass && superClass != parentClass);
        
        if (superClass == nil)
        {
            continue;
        }
        
        [result addObject:classes[i]];
    }
    
    free(classes);
    
    return result;
}
int64_t SystemIdleTime(void) {
    int64_t idlesecs = -1;
    io_iterator_t iter = 0;
    if (IOServiceGetMatchingServices(kIOMasterPortDefault,
                                     IOServiceMatching("IOHIDSystem"),
                                     &iter) == KERN_SUCCESS)
    {
        io_registry_entry_t entry = IOIteratorNext(iter);
        if (entry) {
            CFMutableDictionaryRef dict = NULL;
            kern_return_t status;
            status = IORegistryEntryCreateCFProperties(entry,
                                                       &dict,
                                                       kCFAllocatorDefault, 0);
            if (status == KERN_SUCCESS)
            {
                CFNumberRef obj = CFDictionaryGetValue(dict,
                                                       CFSTR("HIDIdleTime"));
                if (obj) {
                    int64_t nanoseconds = 0;
                    if (CFNumberGetValue(obj,
                                         kCFNumberSInt64Type,
                                         &nanoseconds))
                    {
                        // Convert from nanoseconds to seconds.
                        idlesecs = (nanoseconds >> 30);
                    }
                }
                CFRelease(dict);
            }
            IOObjectRelease(entry);
        }
        IOObjectRelease(iter);
    }
    return idlesecs;
}
@end
