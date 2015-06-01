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
@property (weak) IBOutlet NSPopUpButton *staffSelectorPopup;
@property (weak) IBOutlet NSPopUpButton *templateSelectorPopup;
@property (weak) IBOutlet NSButton *updateFromTemplateButton;
@property NSMutableArray * canDoServiceArray;


@property NSArray * services;
@property NSArray * staff;

@end

@implementation AMCStaffCanDoViewController

-(NSString *)nibName {
    return @"AMCStaffCanDoViewController";
}
-(void)viewDidLoad {
    NSMutableArray * sortDescriptors = [NSMutableArray array];
    [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"serviceName" ascending:YES]];
    [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"employeeCanDo" ascending:YES]];
    [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:@"templateCanDo" ascending:YES]];
    self.canDoTableView.sortDescriptors = sortDescriptors;
}
-(void)prepareForDisplayWithSalon:(AMCSalonDocument *)salonDocument {
    [super prepareForDisplayWithSalon:salonDocument];
    [self reloadStaffArray];
    [self reloadServicesArray];
    [self reloadStaffSelector];
    [self reloadTemplateSelector];
    if (!self.employee) {
        self.employee = self.staff[0];
        self.staffSelectorPopup.enabled = YES;
    } else {
        self.staffSelectorPopup.enabled = NO;
    }
    if (!self.templateEmployee) {
        self.updateFromTemplateButton.enabled = NO;
    }
    [self selectEmployee:self.employee];
    [self selectTemplate:self.templateEmployee];
    [self reloadTable];
    self.selectOnUpdate = YES;
    self.deselectOnUpdate = NO;
}
-(NSMutableDictionary*)canDoDictionaryForRow:(NSInteger)row {
    return self.canDoServiceArray[row];
}
#pragma mark - NSTableViewDelegate and datasource
-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.services.count;
}
-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView * view = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    NSMutableDictionary * canDoDictionary = [self canDoDictionaryForRow:row];
    if ([tableColumn.identifier isEqualToString:@"serviceName"]) {
        view.textField.stringValue = canDoDictionary[tableColumn.identifier];
        return view;
    }
    if ([tableColumn.identifier isEqualToString:@"employeeCanDo"]) {
        NSButton * checkBox = [view viewWithTag:1];
        checkBox.objectValue = canDoDictionary[tableColumn.identifier];
        checkBox.enabled = (self.employee!=nil);
        return view;
    }
    if ([tableColumn.identifier isEqualToString:@"templateCanDo"]) {
        NSButton * checkBox = [view viewWithTag:1];
        checkBox.objectValue = canDoDictionary[tableColumn.identifier];
        checkBox.enabled = NO;
        return view;
    }
    return nil;
}
#pragma mark - Select employee and template
-(void)selectEmployee:(Employee*)employee {
    [self.staffSelectorPopup selectItem:nil];
    for (NSMenuItem * item in self.staffSelectorPopup.menu.itemArray) {
        if (item.representedObject == employee) {
            [self.staffSelectorPopup selectItem:item];
            break;
        }
    }
    [self reloadTable];
}
-(void)selectTemplate:(Employee*)employee {
    for (NSMenuItem * item in self.templateSelectorPopup.menu.itemArray) {
        if (item.representedObject == employee) {
            [self.templateSelectorPopup selectItem:item];
            break;
        }
    }
    [self reloadTable];
}
#pragma mark - Actions

- (IBAction)updateEmployeeFromTemplate:(id)sender {
    for (Service * service in self.services) {
        if (self.selectOnUpdate && [self.templateEmployee.canDo containsObject:service]) {
            [self.employee addCanDoObject:service];
        }
        if (self.deselectOnUpdate && ![self.templateEmployee.canDo containsObject:service]) {
            [self.employee removeCanDoObject:service];
        }
    }
    [self reloadTable];
}
- (IBAction)employeeChanged:(id)sender {
    self.employee = self.staffSelectorPopup.selectedItem.representedObject;
    [self reloadTable];
}
- (IBAction)templateChanged:(id)sender {
    self.templateEmployee = self.templateSelectorPopup.selectedItem.representedObject;
    [self reloadTable];
}
- (IBAction)canDoButtonChanged:(NSButton *)sender {
    NSInteger row = [self.canDoTableView rowForView:sender];
    Service * service = ((NSDictionary*)(self.canDoServiceArray[row]))[@"service"];
    if (sender.state == NSOnState) {
        [self.employee addCanDoObject:service];
    } else {
        [self.employee removeCanDoObject:service];
    }
}
#pragma mark - reload popups
-(void)reloadStaffSelector {
    [self.staffSelectorPopup removeAllItems];
    for (Employee * employee in self.staff) {
        NSMenuItem * item = [[NSMenuItem alloc] init];
        item.representedObject = employee;
        item.title = employee.fullName;
        [self.staffSelectorPopup.menu addItem:item];
    }
}
-(void)reloadTemplateSelector {
    [self.templateSelectorPopup removeAllItems];
    NSMenuItem * item = [[NSMenuItem alloc] init];
    item.title = @"Select template";
    [self.templateSelectorPopup.menu addItem:item];
    item = [NSMenuItem separatorItem];
    [self.templateSelectorPopup.menu addItem:item];
    for (Employee * employee in self.staff) {
        NSMenuItem * item = [[NSMenuItem alloc] init];
        item.representedObject = employee;
        item.title = employee.fullName;
        [self.templateSelectorPopup.menu addItem:item];
    }
}
#pragma mark - reload arrays
-(void)reloadStaffArray {
    self.staff = [Employee allObjectsWithMoc:self.documentMoc];
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES];
    self.staff = [self.staff sortedArrayUsingDescriptors:@[sort]];
}
-(void)reloadServicesArray {
    self.services = [[Service allObjectsWithMoc:self.documentMoc] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hidden = NO"]];
    NSSortDescriptor * sort;
    sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    self.services = [self.services sortedArrayUsingDescriptors:@[sort]];
}
-(void)reloadTable {
    [self reloadCanDoServiceArray];
    [self.canDoTableView reloadData];
    [self enableUpdateButton];
}
-(void)reloadCanDoServiceArray {
    self.canDoServiceArray = [NSMutableArray array];
    for (Service * service in self.services) {
        NSNumber * employeeCanDo = @([[self.employee canDo] containsObject:service]);
        NSNumber * templateCanDo = @([[self.templateEmployee canDo] containsObject:service]);
        NSDictionary * dictionary = @{@"service":service,@"serviceName":service.name, @"employeeCanDo":employeeCanDo, @"templateCanDo":templateCanDo};
        [self.canDoServiceArray addObject:[dictionary mutableCopy]];
    }
}
-(void)enableUpdateButton {
    if (self.employee && self.templateEmployee) {
        self.updateFromTemplateButton.enabled = YES;
    } else {
        self.updateFromTemplateButton.enabled = NO;
    }
}
@end
