//
//  AMCServiceSelectorViewController.m
//  ClaudiasSalon
//
//  Created by service on 14/09/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "AMCServiceSelectorViewController.h"
#import "ServiceCategory+Methods.h"
#import "Service.h"

@interface AMCServiceSelectorViewController ()
{

}
@property NSMutableArray * categories;
@property NSMutableArray * services;
@end

@implementation AMCServiceSelectorViewController

-(NSString *)nibName {
    return @"AMCServiceSelectorViewController";
}
-(void)reloadData {
    [self view];
    [self loadCategoryPopup];
}
- (IBAction)serviceCategoryChanged:(id)sender {
    ServiceCategory * category = self.categories[self.serviceCategoryPopup.indexOfSelectedItem];
    [self loadServiceTableForCategory:category];
}

-(void)loadServiceTableForCategory:(ServiceCategory*)category {
    NSManagedObjectContext * moc = self.documentMoc;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Service" inManagedObjectContext:moc];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"serviceCategory = %@ and hidden = %@", category,@(NO)];
    [fetchRequest setPredicate:predicate];
    // Specify how the fetched objects should be sorted
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name"
                                                                   ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortDescriptor, nil]];
    
    NSError *error = nil;
    self.services = [[moc executeFetchRequest:fetchRequest error:&error] mutableCopy];
    if (self.services == nil) {
        
    }
    [self.servicesTable reloadData];
    [self.delegate serviceSelectorDidChangeSelection:self];
}
-(void)loadCategoryPopup
{
    NSManagedObjectContext * moc = self.documentMoc;
    NSEntityDescription * entityDescription = [NSEntityDescription entityForName:@"ServiceCategory" inManagedObjectContext:moc];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    // Set predicate and sort orderings...
    NSSortDescriptor * sort = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"selectable == %@",@(YES)];
    [request setPredicate:predicate];
    [request setSortDescriptors:@[sort]];
    NSError *error = nil;
    self.categories = [[moc executeFetchRequest:request error:&error] mutableCopy];
    
    if (!self.categories) {
        self.categories = [@[] mutableCopy];
    }
    [self.serviceCategoryPopup removeAllItems];
    [self.serviceCategoryPopup insertItemWithTitle:@"All Categories" atIndex:0];
    NSUInteger i = 1;
    for (ServiceCategory * category in self.categories) {
        NSString * title = category.name;
        [self.serviceCategoryPopup insertItemWithTitle:title atIndex:i];
        i++;
    }
    [self.serviceCategoryPopup selectItemAtIndex:0];
    [self serviceCategoryChanged:self];
}

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.services.count;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView * view = nil;
    if (tableView == self.servicesTable) {
        Service * service = self.services[row];
        view = [tableView makeViewWithIdentifier:@"service" owner:self];
        if (service.deluxe.boolValue) {
            view.imageView.image = [[NSBundle mainBundle] imageForResource:@"GoldStar"];
        } else {
            view.imageView.image = nil;
        }
        view.textField.stringValue = service.name;
    }
    return view;
}

@end
