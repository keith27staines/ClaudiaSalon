//
//  ProductSelectorViewController.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 23/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//
#import <CoreData/CoreData.h>
#import "ProductSelectorViewController.h"
#import "Product+Methods.h"

@interface ProductSelectorViewController ()
@property BOOL loaded;
@end

@implementation ProductSelectorViewController

-(NSString *)nibName
{
    return @"ProductSelectorViewController";
}
-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    Product * product = self.objects[row];
    if ([tableColumn.identifier isEqualToString:@"brandName"]) {
        return product.brandName;
    } else {
        return product.productType;
    }
}

-(NSArray*)objects
{
    if (!self.loaded) {
        self.loaded = YES;
        NSManagedObjectContext * moc = self.documentMoc;
        NSEntityDescription *entityDescription = [NSEntityDescription
                                                  entityForName:@"Product" inManagedObjectContext:moc];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDescription];
        
        // Set predicate and sort orderings...
        NSPredicate *predicate = nil;
        [request setPredicate:predicate];
        
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
                                            initWithKey:@"brandName" ascending:YES];
        [request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
        
        NSError *error = nil;
        NSArray *array = [moc executeFetchRequest:request error:&error];
        if (!array) {
            array = @[];
        }
        [super setObjects:array];
    }
    return super.objects;
}
@end
