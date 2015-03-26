//
//  AMCStaffCanDoViewController.m
//  ClaudiasSalon
//
//  Created by service on 24/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCStaffCanDoViewController.h"
#import "Service+Methods.h"
#import "Employee+Methods.h"

@interface AMCStaffCanDoViewController ()
{

}
@property NSArray * services;
@property NSArray * staff;
@end

@implementation AMCStaffCanDoViewController

-(NSString *)nibName {
    return @"AMCStaffCanDoViewController";
}
-(void)reloadData {
    self.services = [Service allObjectsWithMoc:self.documentMoc];
    NSSortDescriptor * sort;
    sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    self.services = [self.services sortedArrayUsingDescriptors:@[sort]];
    self.staff = [Employee allActiveEmployeesWithMoc:self.documentMoc];
    sort = [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES];
    self.staff = [self.staff sortedArrayUsingDescriptors:@[sort]];
    while (self.canDoTableView.tableColumns.count > 2) {
        [self.canDoTableView removeTableColumn:[self.canDoTableView.tableColumns lastObject]];
    }
    while (self.canDoTableView.tableColumns.count <  self.staff.count + 1 ) {
        NSTableColumn * tableColumn = [[NSTableColumn alloc] init];
        [self.canDoTableView addTableColumn:tableColumn];
    }
    NSInteger staffIndex = -1;
    for (NSTableColumn * column in self.canDoTableView.tableColumns) {
        if ([column.identifier isEqualTo:@"serviceName"]) {
            // leave width of first column alone
        } else {
            staffIndex++;
            column.identifier = [NSString stringWithFormat:@"%li",staffIndex];
            Employee * employee = self.staff[staffIndex];
            [column setWidth:100];
            [[column headerCell] setStringValue:employee.fullName];
        }
    }
    [self.canDoTableView layout];
    [self.canDoTableView reloadData];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.services.count;
}
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView * view;
    Service * service = self.services[row];
    if ([tableColumn.identifier isEqualToString:@"serviceName"]) {
        view = [tableView makeViewWithIdentifier:@"serviceName" owner:self];
        view.textField.stringValue = service.name;
    } else {
        view = [tableView makeViewWithIdentifier:@"canDo" owner:self];
        NSButton * checkBox = [view viewWithTag:1];
        NSInteger staffIndex = tableColumn.identifier.integerValue;
        Employee * employee = self.staff[staffIndex];
        Service * service = self.services[row];
        if ([employee.canDo containsObject:service]) {
            checkBox.state = NSOnState;
        } else {
            checkBox.state = NSOffState;
        }
    }
    return view;
}
- (IBAction)canDoButtonChanged:(NSButton *)sender {
    NSInteger row = [self.canDoTableView rowForView:sender];
    NSInteger col = [self.canDoTableView columnForView:sender];
    Employee * employee = self.staff[col-1];
    Service * service = self.services[row];
    if (sender.state == NSOnState) {
        [employee addCanDoObject:service];
    } else {
        [employee removeCanDoObject:service];
    }
}
@end
