//
//  AMCPermissionDeniedViewController.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCPermissionDeniedViewController.h"
#import "Employee+Methods.h"
#import "BusinessFunction+Methods.h"
#import "Role+Methods.h"
#import "AMCChangeUserViewController.h"
#import "AMCRolesMappingToScreen.h"

@interface AMCPermissionDeniedViewController ()
{
    BusinessFunction * _businessFunction;
}
@property (weak) IBOutlet NSButton *okButton;

@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSTextField *userNameLabel;
@property (weak) IBOutlet NSTextField *businessFunctionLabel;
@property (weak) IBOutlet NSTextField *verbLabel;

@property BOOL cancelRequestPermission;
@property (strong) IBOutlet AMCChangeUserViewController *signInAdministrator;
@property (weak) Employee * requestingPerson;
@property (strong) IBOutlet AMCRolesMappingToScreen *roleToScreenMap;

@end

@implementation AMCPermissionDeniedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.okButton.hidden = !self.callingViewController.permissionDeniedNeedsOKButton;
}
-(void)dismissController:(id)sender {
    SEL cancelButton = NSSelectorFromString(@"cancelButton:");
    if ([self.callingViewController respondsToSelector:cancelButton]) {
        [self.callingViewController performSelectorOnMainThread:cancelButton withObject:nil waitUntilDone:YES];
    }
    [self.callingViewController dismissController:self];
}

-(void)setBusinessFunction:(BusinessFunction *)businessFunction {
    _businessFunction = businessFunction;
}

-(BusinessFunction *)businessFunction {
    return _businessFunction;
}
- (IBAction)requestPermission:(id)sender {
    self.cancelRequestPermission = NO;
    self.requestingPerson = self.callingViewController.salonDocument.currentUser;
    self.signInAdministrator.authorizingMode = YES;
    [self.signInAdministrator prepareForDisplayWithSalon:self.callingViewController.salonDocument];
    [self presentViewControllerAsSheet:self.signInAdministrator];
}
-(void)dismissViewController:(NSViewController *)viewController {
    if (viewController == self.signInAdministrator) {
        [super dismissViewController:viewController];
        if (self.requestingPerson != self.callingViewController.salonDocument.currentUser) {
            // Sign-in process worked, so close permission denied view and show permissions map
            self.roleToScreenMap.mappedBusinessFunction = self.businessFunction;
            self.roleToScreenMap.currentUser = self.requestingPerson;
            self.roleToScreenMap.editMode = EditModeEdit;
            [self.roleToScreenMap prepareForDisplayWithSalon:self.callingViewController.salonDocument];
            [self presentViewControllerAsSheet:self.roleToScreenMap];
        }
        return;
    }
    if (viewController == self.roleToScreenMap) {
        [super dismissViewController:viewController];
        self.callingViewController.salonDocument.currentUser = self.requestingPerson;
        BOOL permissionGranted = NO;
        if (self.requestingPerson) {
            permissionGranted = [self.requestingPerson canPerformBusinessFunction:self.businessFunction verb:self.editModeVerb].boolValue;
        } else {
            permissionGranted = [self.salonDocument.salon.basicUserRole allowsBusinessFunction:self.businessFunction verb:self.editModeVerb].boolValue;
        }
        if (permissionGranted) {
            [self dismissController:self];
            NSAlert * alert = [[NSAlert alloc] init];
            alert.messageText = [NSString stringWithFormat:@"Success!"];
            alert.informativeText = [NSString stringWithFormat:@"You now have permission to access %@ in %@ mode. \n\nPlease try again!",self.businessFunction.functionName,self.editModeVerb];
            [alert runModal];
        } else {
            NSAlert * alert = [[NSAlert alloc] init];
            alert.alertStyle = NSCriticalAlertStyle;
            alert.messageText = [NSString stringWithFormat:@"Permission has not been granted"];
            alert.informativeText = [NSString stringWithFormat:@"You have not been given permission to access \n%@ in %@ mode.",self.businessFunction.functionName,self.editModeVerb];
            [alert runModal];
        }
        return;
    }
    [super dismissViewController:viewController];
}
@end
