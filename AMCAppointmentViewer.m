//
//  AMCAppointmentViewer.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 16/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCAppointmentViewer.h"
#import "Appointment.h"
#import "Sale.h"
#import "Customer.h"
#import "Employee.h"
#import "SaleItem.h"
#import "AMCQuickQuoteViewController.h"

@interface AMCAppointmentViewer ()

@property (strong) IBOutlet NSViewController *appointmentViewController;
@property (strong) IBOutlet NSViewController *saleViewController;
@property (strong) IBOutlet NSViewController *customerViewController;
@property (strong) IBOutlet NSViewController *noInformationViewController;

@property (strong) IBOutlet AMCQuickQuoteViewController *paymentInfoViewController;

@property (weak) IBOutlet NSView *container;
@property (weak) IBOutlet NSSegmentedControl *viewSelector;
@property NSViewController * currentViewController;
@property NSView * currentView;
@property (weak) IBOutlet NSButton *paymentInfoButton;
@property (weak) IBOutlet NSTextField *totalLabel;

@end

@implementation AMCAppointmentViewer

-(NSString *)nibName {
    return @"AMCAppointmentViewer";
}
-(void)viewDidLoad {
    [self addChildViewController:self.appointmentViewController];
    [self addChildViewController:self.saleViewController];
    [self addChildViewController:self.customerViewController];
    [self addChildViewController:self.noInformationViewController];
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self.viewSelector selectSegmentWithTag:self.selectedView];
    [self viewChanged:self];
}
- (IBAction)viewChanged:(id)sender {
    if (!self.currentViewController) {
        self.currentViewController = [self viewControllerForViewNumber:self.selectedView];
        if (!self.currentView) {
            self.currentView = self.currentViewController.view;
            [self.container addSubview:self.currentView];
            return;
        }
    }
    NSViewControllerTransitionOptions options;
    if (self.selectedView > [self.viewSelector selectedSegment]) {
        options = NSViewControllerTransitionSlideRight;
    } else {
        options = NSViewControllerTransitionSlideLeft;
    }
    self.selectedView = [self.viewSelector selectedSegment];
    NSViewController * nextViewController = [self viewControllerForViewNumber:self.selectedView];
    if (self.currentViewController == nextViewController) return;
    [self transitionFromViewController:self.currentViewController toViewController:nextViewController options:options completionHandler:^{
        self.currentViewController = nextViewController;
        self.currentView = self.currentViewController.view;
    }];
}
-(NSViewController*)viewControllerForViewNumber:(AMCAppointmentViews)viewNumber {
    NSViewController * viewController = nil;
    switch (viewNumber) {
        case AMCAppointmentViewAppointment: {
            if (self.appointment) {
                viewController = self.appointmentViewController;
            }
            break;
        }
        case AMCAppointmentViewSale: {
            if (self.sale && !self.sale.hidden.boolValue) {
                viewController = self.saleViewController;
            }
            break;
        }
        case AMCAppointmentViewCustomer: {
            viewController = self.customerViewController;
            break;
        }
    }
    if (!viewController) {
        viewController = self.noInformationViewController;
    }
    return viewController;
}
- (IBAction)showPaymentInfo:(id)sender {
    self.paymentInfoViewController.sale = self.sale;
    [self.paymentInfoViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewController:self.paymentInfoViewController asPopoverRelativeToRect:self.totalLabel.bounds ofView:self.totalLabel preferredEdge:NSMaxXEdge behavior:NSPopoverBehaviorTransient];
}
@end
