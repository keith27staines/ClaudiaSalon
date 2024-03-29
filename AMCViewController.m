//
//  AMCViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 21/02/2015.
//  Copyright (c) 2015 Keith Staines. All rights reserved.
//

#import "AMCViewController.h"
#import "AMCSalonDocument.h"
#import "AMCPermissionDeniedViewController.h"
#import "Role.h"
#import "Employee.h"
#import "AMCRolesMappingToScreen.h"
#import "BusinessFunction.h"

@interface AMCViewController ()
{
    AMCPermissionDeniedViewController * _permissionDeniedViewController;
    AMCRolesMappingToScreen * _rolesToScreenMapViewController;
}
@property (strong,readonly) AMCPermissionDeniedViewController * permissionDeniedViewController;
@property (strong,readonly) AMCRolesMappingToScreen * rolesToScreenMapViewController;
@property EditMode editMode;
@property NSView * myView;

@end

@implementation AMCViewController


-(NSManagedObjectContext *)documentMoc {
    return self.salonDocument.managedObjectContext;
}
-(void)reloadDataMaintainingSelection:(BOOL)maintainSelection {
    [self reloadData];
}
-(void)reloadData {

}
-(BusinessFunction *)businessFunction {
    return [BusinessFunction fetchBusinessFunctionWithCodeUnitName:self.className inMoc:self.documentMoc];
}
-(instancetype)init {
    self = [super init];
    if (self) {
        self.editMode = EditModeView;
    }
    return self;
}
-(BOOL)permissionDeniedNeedsOKButton {
    return YES;
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument*)salonDocument {
    NSAssert(salonDocument, @"The salonDocument should not be nill");
    self.salonDocument = salonDocument;
    BOOL isAllowed = NO;
    Employee * employee = salonDocument.currentUser;
    if (!self.myView) {
        self.myView = self.view;
    }
    if (employee) {
        isAllowed = [employee canPerformBusinessFunction:self.businessFunction verb:self.editModeVerb].boolValue;
    } else {
        Role * role = salonDocument.salon.basicUserRole;
        isAllowed = [role allowsBusinessFunction:self.businessFunction verb:self.editModeVerb].boolValue;
    }
    if (isAllowed) {
        self.view = self.myView;
        [self reloadData];
    } else {
        self.permissionDeniedViewController.businessFunction = self.businessFunction;
        self.permissionDeniedViewController.editModeVerb = self.editModeVerb;
        self.permissionDeniedViewController.currentUser = self.salonDocument.currentUser;
        self.permissionDeniedViewController.salonDocument = self.salonDocument;
        self.view = self.permissionDeniedViewController.view;
    }
}
-(NSString *)editModeVerb {
    switch (self.editMode) {
        case EditModeView:
            return @"View";
        case EditModeEdit:
            return @"Edit";
        case EditModeCreate:
            return @"Create";
    }
}
-(AMCPermissionDeniedViewController *)permissionDeniedViewController {
    if (!_permissionDeniedViewController) {
        _permissionDeniedViewController = [[AMCPermissionDeniedViewController alloc] init];
    }
    _permissionDeniedViewController.callingViewController = self;
    return _permissionDeniedViewController;
}
-(IBAction)showRolesToCodeUnitMapping:(id)sender {
    [self.rolesToScreenMapViewController prepareForDisplayWithSalon:self.salonDocument];
    [self presentViewControllerAsSheet:self.rolesToScreenMapViewController];
}
-(AMCRolesMappingToScreen *)rolesToScreenMapViewController {
    if (!_rolesToScreenMapViewController) {
        _rolesToScreenMapViewController = [[AMCRolesMappingToScreen alloc] init];
    }
    _rolesToScreenMapViewController.mappedBusinessFunction = self.businessFunction;
    _rolesToScreenMapViewController.currentUser = self.salonDocument.currentUser;
    return _rolesToScreenMapViewController;
}
@end
