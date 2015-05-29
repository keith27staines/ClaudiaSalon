//
//  AMCSalonDocument.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class Salon,AMCReportsViewController;
@class AMCAppointmentsViewController;
@class AMCSalesViewController;
@class AMCPaymentsViewController;
@class AMCStockControlViewController;
@class AMCRequestPasswordWindowController;
@class AMCDayAndMonthPopupViewController;
@class EditObjectViewController;
@class AMCServicesViewController;
@class AMCServiceCategoriesViewController;
@class AMCEmployeesViewController;
@class AMCCustomersViewController;

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>
#import "NSPersistentDocument+SalonMethods.h"
#import "NSViewController+SalonMethods.h"
#import "AMCConstants.h"
#import "AMCViewController.h"
#import "Salon+Methods.h"

@interface AMCSalonDocument : NSPersistentDocument 
@property (readonly) Salon * salon;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
-(void)enableViewItemButtonForTableViews;
@property BOOL storeNeedsInitializing;
@property (readonly) Customer * anonymousCustomer;

// Toolbar actions
- (IBAction)salonToolbarButton:(id)sender;
- (IBAction)showMoneyInTill:(id)sender;

// Top tab view
@property (weak) IBOutlet NSTabView *topTabView;


// Appointments tab
@property (weak) IBOutlet AMCAppointmentsViewController * appointmentsViewController;

// Sales tab
@property (weak) IBOutlet AMCSalesViewController * salesViewController;

// Payments tab
@property (weak) IBOutlet AMCPaymentsViewController *paymentsViewController;


// Services tab
@property (strong) IBOutlet AMCServicesViewController *servicesViewController;

// Service category tab
@property (strong) IBOutlet AMCServiceCategoriesViewController *serviceCategoriesViewController;

// Stock tab
@property (weak) IBOutlet AMCStockControlViewController * stockViewController;

// Reports tab
@property (weak) IBOutlet AMCReportsViewController *reportsViewController;

// Employee tab
@property (strong) IBOutlet AMCEmployeesViewController *employeesViewController;

@property (weak) IBOutlet NSView *employeesView;
@property (weak) IBOutlet NSTableView *employeesTable;
@property (weak) IBOutlet NSArrayController *employeeArrayController;
-(IBAction)createEmployeeButtonClicked:(id)sender;
-(IBAction)viewEmployeeButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton *createEmployeeButton;
@property (weak) IBOutlet NSButton *viewEmployeeButton;
@property (weak) IBOutlet EditObjectViewController * editEmployeeViewController;
@property (weak) IBOutlet NSButton *showEmployeeNotesButton;
- (IBAction)showEmployeeNotesButtonClicked:(id)sender;
- (IBAction)showCanDoListButtonClicked:(id)sender;


// Customer tab
@property (strong) IBOutlet AMCCustomersViewController *customersViewController;

@property (weak) IBOutlet NSView *customerView;
@property (weak) IBOutlet NSTableView * customerTable;
@property (weak) IBOutlet NSArrayController * customerArrayController;
-(IBAction)createCustomerButtonClicked:(id)sender;
-(IBAction)viewCustomerButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton * createCustomerButton;
@property (weak) IBOutlet NSButton * viewCustomerButton;
@property (weak) IBOutlet EditObjectViewController * editCustomerViewController;
@property (weak) IBOutlet NSButton *showCustomerNotesButton;
- (IBAction)showCustomerNotesButtonClicked:(id)sender;
- (IBAction)clearCustomerFilters:(id)sender;
@property (weak) IBOutlet NSButton *clearFiltersButton;
@property (weak) IBOutlet NSTextField *firstNameFilter;
@property (weak) IBOutlet NSTextField *lastNameFilter;
@property (weak) IBOutlet NSTextField *emailAddressFilter;
@property (weak) IBOutlet NSTextField *phoneFilter;
@property (weak) IBOutlet AMCDayAndMonthPopupViewController *birthdayPopupFilter;


@end
