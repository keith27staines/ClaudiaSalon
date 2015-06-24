//
//  Role.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 23/06/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "Role.h"
#import "Employee.h"
#import "RoleAction.h"
#import "Salon.h"


@implementation Role

@dynamic fullDescription;
@dynamic name;
@dynamic isSystemRole;
@dynamic allowedActions;
@dynamic employeesInRole;
@dynamic systemRoleForSalon;
@dynamic devSupportRoleForSalon;
@dynamic systemAdminRoleForSalon;
@dynamic managerRoleForSalon;
@dynamic accountantRoleForSalon;
@dynamic receptionistRoleForSalon;
@dynamic basicUserRoleForSalon;

@end
