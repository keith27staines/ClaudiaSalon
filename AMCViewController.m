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
#import "Role+Methods.h"
#import "Employee+Methods.h"

@interface AMCViewController ()
{
    AMCPermissionDeniedViewController * _permissionDeniedViewController;
}
@property (strong,readonly) AMCPermissionDeniedViewController * permissionDeniedViewController;
@property EditMode editMode;
@property NSView * myView;
@end

@implementation AMCViewController


-(NSManagedObjectContext *)documentMoc {
    NSAssert(self.salonDocument, @"Salon is nil");
    return self.salonDocument.managedObjectContext;
}

-(void)reloadData {

}
-(instancetype)init {
    self = [super init];
    if (self) {
        self.editMode = EditModeView;
    }
    return self;
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument*)salonDocument {
    NSAssert(salonDocument, @"The salonDocument should not be nill");
    self.salonDocument = salonDocument;
    BOOL isAllowed = NO;
    Employee * employee = salonDocument.currentUser;
    if (!self.myView) {
        self.myView = [self view];
    }
    if (employee) {
        isAllowed = [employee canPerformAction:self.className withActionName:self.editModeVerb].boolValue;
    } else {
        Role * role = salonDocument.salon.basicUserRole;
        isAllowed = [role allowsActionWithCodeUnitName:self.className actionName:self.editModeVerb].boolValue;
    }
    if (isAllowed) {
        self.view = self.myView;
        [self reloadData];
    } else {
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
@end
