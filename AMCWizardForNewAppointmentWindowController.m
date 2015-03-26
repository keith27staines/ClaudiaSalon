//
//  AMCWizardForNewAppointmentWindowController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/08/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCWizardForNewAppointmentWindowController.h"
#import "AMCWizardStepSelectCustomerViewController.h"
#import "AMCWizardStepBookAppointmentForCustomerViewController.h"
#import "Appointment+Methods.h"
#import "Sale+Methods.h"

typedef NS_ENUM(NSUInteger, AMCWizardStepsMakeAppointment) {
    AMCWizardStepsMakeAppointmentSelectCustomer = 0,
    AMCWizardStepsMakeAppointmentBookTime,
};

@interface AMCWizardForNewAppointmentWindowController ()
@property (readonly) Appointment * appointment;
@end

@implementation AMCWizardForNewAppointmentWindowController

#pragma mark - methods that ought to be overriden
-(void)addWizardStepControllers {
    self.wizardStepControllers = [NSMutableArray array];
    // Add select customer step
    AMCWizardStepViewController * wizardStep;
    wizardStep = [[AMCWizardStepSelectCustomerViewController alloc] init];
    wizardStep.salonDocument = self.document;
    [self addWizardStepViewController:wizardStep];
    wizardStep.delegate = self;
    wizardStep.objectToManage = self.appointment.customer;
    // Add book appointment step
    wizardStep = [[AMCWizardStepBookAppointmentForCustomerViewController alloc] init];
    wizardStep.salonDocument = self.document;
    [self addWizardStepViewController:wizardStep];
    wizardStep.delegate = self;
    wizardStep.objectToManage = self.appointment;
}
-(NSString*)titleForStepWithIndex:(NSUInteger)index {
    AMCWizardStepsMakeAppointment step = index;
    switch (step) {
        case AMCWizardStepsMakeAppointmentSelectCustomer:
            return @"Book appointment for customer";
        case AMCWizardStepsMakeAppointmentBookTime:
            return @"Book date, time and services";
    }
}
#pragma mark - methods designed to be (optionally!) overriden
-(BOOL)wizardStepCanBeSkippedWithIndex:(NSUInteger)index {
    return NO;
}
-(void)updateEnabledAndVisiblePropertiesForWizardButton:(NSButton*)wizardButton onWizardStep:(NSUInteger)step {
    [super updateEnabledAndVisiblePropertiesForWizardButton:wizardButton onWizardStep:step];
    return;
}
-(void)selectWizardStep:(NSUInteger)newIndex {
    AMCWizardStepsMakeAppointment currentStep = self.selectedIndex;
    switch (currentStep) {
        case AMCWizardStepsMakeAppointmentSelectCustomer:
        {
            // Moving away from customer selection step so we set the customer on the appointment object from the customer just selected
            self.appointment.customer = self.selectedStepController.objectToManage;
            self.appointment.sale.customer = self.appointment.customer;
            break;
        }
        case AMCWizardStepsMakeAppointmentBookTime:
        {
            break;
        }
    }
    [super selectWizardStep:newIndex];
}
-(Appointment*)appointment {
    return (Appointment*)self.objectToManage;
}

@end
