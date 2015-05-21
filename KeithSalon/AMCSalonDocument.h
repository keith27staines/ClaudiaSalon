//
//  AMCSalonDocument.h
//  ClaudiasSalon
//
//  Created by Keith Staines on 19/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

@class Salon,AMCReportsViewController;
@class AMCAppointmentsViewController;
@class AMCPaymentsViewController;
@class AMCStockControlViewController;
@class AMCRequestPasswordWindowController;
@class AMCDayAndMonthPopupViewController;
@class EditObjectViewController;

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

// Toolbar actions
- (IBAction)salonToolbarButton:(id)sender;
- (IBAction)showMoneyInTill:(id)sender;

// Top tab view
@property (weak) IBOutlet NSTabView *topTabView;

// Reports tab
@property (weak) IBOutlet AMCReportsViewController *reportsViewController;

// Appointments tab
@property (weak) IBOutlet AMCAppointmentsViewController * appointmentsViewController;


// Payments tab
@property (weak) IBOutlet AMCPaymentsViewController *paymentsViewController;

// Stock tab
@property (weak) IBOutlet AMCStockControlViewController * stockViewController;// Sales tab

// Sales tab
@property (weak) IBOutlet NSTextField * totalsLabel;
@property (weak) IBOutlet NSView *salesView;
@property (weak) IBOutlet NSArrayController *saleArrayController;
@property (weak) IBOutlet NSTableView *salesTable;
-(IBAction)createSaleButtonClicked:(id)sender;
-(IBAction)viewSaleButtonClicked:(id)sender;
-(IBAction)viewReceiptButtonClicked:(id)sender;
-(IBAction)viewCustomerFromSaleButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton *createSaleButton;
@property (weak) IBOutlet NSButton *viewSaleButton;
@property (weak) IBOutlet NSButton *viewReceiptButton;
@property (weak) IBOutlet NSButton * viewCustomerFromSaleButton;
@property (weak) IBOutlet EditObjectViewController * editSaleViewController;
@property (weak) IBOutlet NSButton *showSaleNotesButton;
- (IBAction)showSaleNotesButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton *voidSaleButton;
- (IBAction)voidSaleButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton *showQuickQuoteButton;
- (IBAction)showQuickQuoteButtonClicked:(id)sender;

// Services tab
@property (weak) IBOutlet NSView *servicesView;
@property (weak) IBOutlet NSArrayController *serviceArrayController;
@property (weak) IBOutlet NSTableView *servicesTable;
- (IBAction)createServiceButtonClicked:(id)sender;
- (IBAction)viewServiceButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton *createServiceButton;
@property (weak) IBOutlet NSButton *viewServiceButton;
@property (weak) IBOutlet EditObjectViewController * editServiceViewController;
@property (weak) IBOutlet NSButton *showServiceNotesButton;
- (IBAction)showServiceNotesButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton *showServiceCategoryNotesButton;
- (IBAction)showServiceCategoryNotesButtonClicked:(id)sender;

// Employee tab
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

// Service category tab
@property (weak) IBOutlet NSView *serviceCategoryView;
@property (weak) IBOutlet NSTableView * serviceCategoryTable;
@property (weak) IBOutlet NSArrayController * serviceCategoryArrayController;
-(IBAction)createServiceCategoryButtonClicked:(id)sender;
-(IBAction)viewServiceCategoryButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton * createServiceCategoryButton;
@property (weak) IBOutlet NSButton * viewServiceCategoryButton;
@property (weak) IBOutlet EditObjectViewController * editServiceCategoryViewController;

// Customer tab
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
