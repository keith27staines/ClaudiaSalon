//
//  AMCSalonDocument.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
#import <objc/runtime.h>
#import <IOKit/IOKitLib.h>
#import <CloudKit/CloudKit.h>
#import "ClaudiaSalon-Swift.h"
#import "AMCSalonDocument.h"
#import "AMCStorePopulator.h"
#import "AMCReportsViewController.h"

#import "AMCViewController.h"
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

#import "Salon.h"
#import "Customer.h"
#import "NSDate+AMCDate.h"
#import "AMCSalonDetailsViewController.h"
#import "RecurringItem+Methods.h"
#import "AMCChangeUserViewController.h"
#import "AMCPermissionsForRoleEditor.h"
#import "AMCRoleMaintenance.h"

// Imports required for data fixes
#import "ServiceCategory.h"
#import "AccountingPaymentGroup+Methods.h"
#import "PaymentCategory.h"
#import "Employee.h"
#import "Role.h"
#import "BusinessFunction.h"
#import "Permission.h"
#import "Sale.h"
#import "SaleItem.h"
#import "Payment.h"
#import "Customer.h"
#import "Appointment.h"
#import "Account.h"
#import "Payment.h"
// End imports for data fixes

static NSString * const kAMCDataStoreDirectory = @"kAMCDataStoreDirectory";

@interface AMCSalonDocument() <NSTabViewDelegate,NSMenuDelegate>
{
    BOOL _storeNeedsInitializing;
    Salon * _salon;
    OpeningHoursWeekTemplate * _openingHoursWeekTemplate;
    Employee * _currentUser;
    NSManagedObjectContext * _moc;
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
@property (weak) AMCViewController * selectedViewController;

@property (strong) IBOutlet AMCFinancialAnalysisViewController *financialAnalysisViewController;

@property NSViewAnimation * notesUpAnimation;
@property NSViewAnimation * notesDownAnimation;
@property NSRect notesButtonInitialRect;
@property NSURL * dataStoreDirectory;
@property (strong) IBOutlet AMCChangeUserViewController *changeUserViewController;

@property (strong) IBOutlet AMCPermissionsForRoleEditor *permissionsForRoleEditor;
@property (strong) IBOutlet AMCRoleMaintenance *roleMaintenance;

@property (weak) IBOutlet NSMenu *switchUserMenu;
@property (weak) IBOutlet NSMenuItem *titleItem;
@property (weak) IBOutlet NSMenuItem *logoutMenuItem;
@property (weak) IBOutlet NSMenuItem *switchUserMenuIem;
@property (weak) IBOutlet NSToolbarItem *toolbarUserPhotoItem;

@property (strong) IBOutlet AMCAccountReconciliationViewController *accountBalanceViewController;
@property (strong) BQCoredataExportController * coredataExportController;
@property (strong) BQCloudImporter * cloudImporter;

@end

@implementation AMCSalonDocument
- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserverForName:@"CloudNotificationsWereProcessed" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
            [self refreshFromCloud:self];
        }];
    }
    return self;
}
-(void)processRecurringEvents:(id)sender {
    [RecurringItem processOutstandingItemsFor:self.managedObjectContext error:nil];
}
-(void)close {
    [self suspendImportsAndExports:true];
    self.cloudImporter = nil;
    self.coredataExportController = nil;
    [super close];
}
-(void)deleteSubscriptions {
    [self.cloudImporter deleteSubscriptions:^void(BOOL success) {
        
    }];
}
-(void)suspendImportsAndExports:(BOOL)suspend {
    if(suspend) {
        if (self.cloudImporter) {
            [self.cloudImporter suspendCloudNotificationProcessing];
        }
        if (self.coredataExportController) {
            [self.coredataExportController suspendExportIterations];
        }
    } else {
        if (self.cloudImporter) {
            [self.cloudImporter resumeCloudNotificationProcessing];
        }
        if (self.coredataExportController) {
            [self.coredataExportController resumeExportIterations];            
        }
    }
}
-(Salon *)salon {
    if (!_salon) {
        _salon = [Salon salonWithMoc:self.managedObjectContext];
        [self dataFixes];
        [self processRecurringEvents:self];
        [NSTimer scheduledTimerWithTimeInterval:3600 target:self selector:@selector(processRecurringEvents:) userInfo:nil repeats:YES];
        
        NSString * containerIdentifer = [CKContainer defaultContainer].containerIdentifier;
        
        self.coredataExportController = [[BQCoredataExportController alloc] initWithParentMoc:self.managedObjectContext iCloudContainerIdentifier:containerIdentifer startProcessingImmediately:NO];
        
        if (_salon.bqCloudID != nil && _salon.bqCloudID.length > 0 ) {
            self.cloudImporter = [[BQCloudImporter alloc] initWithParentMoc:self.managedObjectContext containerIdentifier:containerIdentifer salonCloudRecordName:_salon.bqCloudID];        
        }
        [self suspendImportsAndExports:true];
    }
    return _salon;
}
-(NSManagedObjectContext *)managedObjectContext {
    if (!_moc) {
        NSManagedObjectContext * man = [super managedObjectContext];
        _moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _moc.persistentStoreCoordinator = man.persistentStoreCoordinator;
    }
    return _moc;
}
-(IBAction)showRolesToCodeUnitMapping:(id)sender {
    [self.selectedViewController showRolesToCodeUnitMapping:self];
}
-(void)dataFixes {
    for (Appointment * appointment in [Appointment allObjectsWithMoc:self.managedObjectContext]) {
        if (!appointment.customer && !appointment.sale.customer) {
            appointment.customer = self.anonymousCustomer;
            appointment.sale.customer = self.anonymousCustomer;
        } else {
            if (!appointment.customer) {
                appointment.customer = appointment.sale.customer;
            } else {
                appointment.sale.customer = appointment.customer;
            }
        }
    }
    
    // Begin fix for payments associated with sales that have suffered reversion to quote state
    
    for (Sale * sale in [Sale allObjectsWithMoc:self.managedObjectContext]) {
        if (sale.isQuote.boolValue && sale.hidden.boolValue == false && !sale.voided.boolValue) {
            NSSet<Payment*> * payments = sale.payments;
            NSInteger paymentCount = payments.count;
            if (payments.count == 0) {
                // Sale in quote state but has no payments. This is a legitimate state so we do nothing
                continue;
            } else {
                NSLog(@"Sale has %li payment(s) but is in quote state - amount outstanding is/: %f",(long)paymentCount,sale.amountOutstanding);
                for (Payment * payment in payments) {
                    if (payment.amount.doubleValue == 0.0) {
                        [self.managedObjectContext deleteObject:payment];
                    }
                }
                sale.isQuote = @NO;
                [Sale markSaleForExportInMoc:self.managedObjectContext saleID:sale.objectID];
            }
        }
    }

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
            NSLog(@"Service name = %@",category.name);
            if ([category.name isEqualToString:@"Hair"] || [category.name isEqualToString:@"Beauty"]) {
                continue;
            }
            if (!category.parent && category != rootServiceCategory) {
                if ([category isHairCategory]) {
                    category.parent = hairCategory;
                } else {
                    category.parent = beautyCategory;
                }
                category.salon = _salon;
            }
        }
    }
    for (ServiceCategory * category in [ServiceCategory allObjectsWithMoc:self.managedObjectContext]) {
        if (category.salon == nil) {
            category.salon = _salon;
        }
    }
    for (ServiceCategory * category in rootServiceCategory.subCategories) {
        if (category.salon == nil) {
            category.salon = _salon;
        }
    }
    // End Service Category data fix
    
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
        self.salon.systemAdminRole.fullDescription  = @"System Administrators have the permissions required to configure the application";
        self.salon.devSupportRole.fullDescription   = @"Developers have access to functions that allow them to investigate and debug problems";
        self.salon.managerRole.fullDescription      = @"Managers have access to all business functions but not to technical functions";
        self.salon.accountantRole.fullDescription   = @"Accountants have access to financial functions but not to day-to-day business functions";
        self.salon.receptionistRole.fullDescription = @"Receptionists have permissions that allow them to take appointments and enter sales";
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
    BusinessFunction * businessFunction = nil;

    for (Class class in viewControllerClasses) {
        NSString * className = NSStringFromClass(class);
        
        businessFunction = [BusinessFunction fetchBusinessFunctionWithCodeUnitName:className inMoc:self.managedObjectContext];
        if (businessFunction) continue; // Already added this view action and its related edit/create/delete actions
        
        // add business function
        businessFunction = [BusinessFunction newObjectWithMoc:self.managedObjectContext];
        businessFunction.codeUnitName = className;
        businessFunction.functionName = [self generateFunctionName:businessFunction];
        
        for (Role * role in [Role allObjectsWithMoc:self.managedObjectContext]) {
            Permission * permission = [Permission newObjectWithMoc:self.managedObjectContext];
            permission.role = role;
            permission.businessFunction = businessFunction;
            if (role == self.salon.managerRole || role == self.salon.systemAdminRole || role == self.salon.systemRole) {
                permission.viewAction = @YES;
                permission.editAction = @YES;
                permission.createAction = @YES;
            } else {
                permission.viewAction = @YES;
                permission.editAction = @NO;
                permission.createAction = @NO;
            }
        }
    }
    
    // Match sales to corresponding payments
    NSArray * allPayments = [Payment allObjectsWithMoc:self.managedObjectContext];
    NSMutableArray * unmatchedPayments = [NSMutableArray array];
    for (Payment * payment in allPayments) {
        if (!payment.sale && payment.paymentCategory.isSale.boolValue && !payment.voided.boolValue) {
            [unmatchedPayments addObject:payment];
        }
    }
    long matchedSales = 0;
    BOOL matchFound = NO;
    NSMutableArray * unmatchedSales = [NSMutableArray array];
    for (Sale * sale in [Sale allObjectsWithMoc:self.managedObjectContext]) {
        matchFound = NO;
        if (sale.isQuote.boolValue) { continue; }
        if (sale.voided.boolValue) { continue; }
        if (sale.payments.count > 0) { continue; }
        for (Payment * payment in [unmatchedPayments copy]) {
            if ([self payment:payment matchesSale:sale]) {
                // Match
                matchedSales++;
                [unmatchedPayments removeObject:payment];
                matchFound = YES;
                
                // This line alters data!!!!!
                [sale addPaymentsObject:payment];
                break;
            }
        }
        if (!matchFound) {
            [unmatchedSales addObject:sale];
        }
    }
    NSLog(@"Matched sales: %@.  Unmatched sales: %@",@(matchedSales),@(unmatchedSales.count));
    for (Sale * sale in unmatchedSales) {
        if (!sale.customer) {
            sale.customer = self.salon.anonymousCustomer;
        }
        if (!sale.account) {
            sale.account = self.salon.tillAccount;
        }
        [sale makePaymentInFull];
    }
    NSMutableArray * anonCustomers = [NSMutableArray array];
    Customer * theAnonymousCustomer = self.salon.anonymousCustomer;
    for (Customer * customer in [Customer allObjectsWithMoc:self.managedObjectContext]) {
        NSString * firstName;
        if (!customer.firstName) {
            firstName = @"0000";
        } else {
            firstName = [customer.firstName stringByAppendingString:@"0000"];
        }
        if ([[firstName substringToIndex:4] isEqualToString:@"Anon"]) {
            [anonCustomers addObject:customer];
        }
        if ([[firstName substringToIndex:1] isEqualToString:@"0"] && [[customer.phone substringToIndex:5] isEqualToString:@"00000"]) {
            [anonCustomers addObject:customer];
        }
    }
    
    for (Customer * customer in anonCustomers) {
        NSLog(@"Full name: %@",customer.fullName);
        if (customer == self.salon.anonymousCustomer) {
            continue;
        }
        for (Sale * sale in [customer.sales copy]) {
            sale.customer = theAnonymousCustomer;
        }
        for (Appointment * appointment in [customer.appointments copy]) {
            appointment.customer = self.salon.anonymousCustomer;
        }
        if (customer != self.salon.anonymousCustomer) {
            [self.managedObjectContext deleteObject:customer];
        }
    }
    
    // Recalculate fees and net amount for all card payments
    Account * paypal = self.salon.cardPaymentAccount;
    if (paypal.transactionFeePercentageIncoming.doubleValue == 0) {
        paypal.transactionFeePercentageIncoming = @0.0275;
    }
    for (Payment * payment in [Payment allObjectsWithMoc:self.managedObjectContext]) {
        if (payment.amountNet.doubleValue == 0) {
            [payment recalculateFromCurrentAmount];
        }
    }
    
    // Change discount model
    NSMutableArray * allSales = [[Sale allObjectsWithMoc:self.managedObjectContext] mutableCopy];
    [allSales sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        Sale * sale1 = (Sale*)obj1;
        Sale * sale2 = (Sale*)obj2;
        if ([sale1.lastUpdatedDate isGreaterThan:sale2.lastUpdatedDate]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        
        if ([sale1.lastUpdatedDate isLessThan:sale2.lastUpdatedDate]) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    for (Sale * sale in allSales) {
        if (!sale.customer) {
            sale.customer = self.anonymousCustomer;
        }
        if (sale.discountVersion.integerValue >=2) {
            continue;
        }
        [sale convertToDiscountVersion2];
    }
}

-(BOOL)payment:(Payment*)payment matchesSale:(Sale*)sale {
    if (!payment) { return NO; }
    if (!sale) { return NO; }
    if (payment.sale == sale) return YES;
    if (![payment.direction isEqualToString:kAMCPaymentDirectionIn]) { return NO; };
    if (payment.amount.doubleValue != sale.actualCharge.doubleValue) { return NO; }
    long paymentDate = payment.paymentDate.timeIntervalSinceReferenceDate;
    long saleDate = sale.lastUpdatedDate.timeIntervalSinceReferenceDate;
    
    if (sale.customer) {
        if (![payment.payeeName isEqualToString:sale.customer.fullName]) {
            return NO;
        }
        if (labs(paymentDate-saleDate)>24*3600) { return NO; }
    } else {
        if (![payment.payeeName isEqualToString:@"Customer"]) {
            return NO;
        }
        if (labs(paymentDate-saleDate)>3600) { return NO; }
    }
    return YES;
}

-(NSString*)generateFunctionName:(BusinessFunction*)businessFunction {
    NSMutableString * friendlyName = [businessFunction.codeUnitName mutableCopy];
    [friendlyName replaceOccurrencesOfString:@"ViewController" withString:@"" options:0 range:NSMakeRange(0, friendlyName.length)];
    
    // Find first lowercase character
    int firstLower = 0;
    for (int i = 0; i < friendlyName.length; i++) {
        NSString * c = [friendlyName substringWithRange:NSMakeRange(i, 1)];
        if ([c isEqualToString:[c uppercaseString]]) {
            continue;
        } else {
            firstLower = i;
            break;
        }
    }
    // Remove all but the last of the preceeding uppercase characters
    if (firstLower > 0) {
        friendlyName = [[friendlyName substringFromIndex:firstLower - 1] mutableCopy];
    }
    // Put a space after any lower case letter that preceeds an upper case letter
    int i = 0;
    while (i < friendlyName.length - 2) {
        NSString * c1 = [friendlyName substringWithRange:NSMakeRange(i, 1)];
        NSString * c2 = [friendlyName substringWithRange:NSMakeRange(i+1,1)];
        if ([c1 isEqualToString:[c1 lowercaseString]] && [c2 isEqualToString:[c2 uppercaseString]]) {
            [friendlyName insertString:@" " atIndex:i+1];
            i += 2;
        }
        i++;
    }
    return friendlyName;
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
    super.managedObjectContext = self.managedObjectContext;
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
    while (container.subviews.count > 0) {
        [container.subviews.firstObject removeFromSuperviewWithoutNeedingDisplay];
    }
    self.selectedViewController = viewController;
    [viewController prepareForDisplayWithSalon:self];
    NSView * view = viewController.view;
    [view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [container addSubview:view];
    NSDictionary * views = NSDictionaryOfVariableBindings(view);
    NSArray * constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[view]-|" options:0 metrics:nil views:views];
    [container addConstraints:constraints];
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[view]-|" options:0 metrics:nil views:views];
    [container addConstraints:constraints];
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
    AMCAccountReconciliationViewController * vc = (AMCAccountReconciliationViewController*)self.accountBalanceViewController;
    vc.account = self.salon.tillAccount;
    [vc prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:vc];
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
- (IBAction)refreshFromCloud:(id)sender {
    [self.appointmentsViewController reloadDataMaintainingSelection:YES];
    [self.salesViewController reloadDataMaintainingSelection:YES];
    [self.customersViewController reloadDataMaintainingSelection:YES];
    [self.paymentsViewController reloadDataMaintainingSelection:YES];
    [self.servicesViewController reloadDataMaintainingSelection:YES];
    [self.employeesViewController reloadDataMaintainingSelection:YES];
    [self.stockViewController reloadDataMaintainingSelection:YES];
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
-(IBAction)userIconClicked:(id)sender {
    [self switchUser:self];
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
- (IBAction)showPermissionsForRoleEditor:(id)sender {
    [self.permissionsForRoleEditor prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.permissionsForRoleEditor];
}
- (IBAction)showRoleMaintenance:(id)sender {
    [self.roleMaintenance prepareForDisplayWithSalon:self];
    [self.mainViewController presentViewControllerAsSheet:self.roleMaintenance];
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
