//
//  ServiceCategory+Methods.m
//  ClaudiasSalon
//
//  Created by Keith Staines on 24/07/2014.
//  Copyright (c) 2014 Keith Staines. All rights reserved.
//

#import "ServiceCategory+Methods.h"
#import "Service+Methods.h"

@implementation ServiceCategory (Methods)
+(id)newObjectWithMoc:(NSManagedObjectContext*)moc
{
    ServiceCategory * serviceCategory = [NSEntityDescription insertNewObjectForEntityForName:@"ServiceCategory"
                                                                      inManagedObjectContext:moc];
    NSDate * rightNow = [NSDate date];
    serviceCategory.createdDate = rightNow;
    serviceCategory.lastUpdatedDate = rightNow;
    serviceCategory.salon = [Salon salonWithMoc:moc];
    serviceCategory.parent = serviceCategory.salon.rootServiceCategory;
    return serviceCategory;
}
+(NSArray*)allObjectsWithMoc:(NSManagedObjectContext*)moc {
    NSArray * array = nil;
    NSFetchRequest * fetch = [NSFetchRequest fetchRequestWithEntityName:@"ServiceCategory"];
    array = [moc executeFetchRequest:fetch error:nil];
    return array;
}
-(NSSet*)nonAuditNotes {
    NSMutableSet * nonAuditNotes = [NSMutableSet set];
    for (Note * note in self.notes) {
        if (!note.isAuditNote.boolValue) {
            [nonAuditNotes addObject:note];
        }
    }
    return nonAuditNotes;
}

-(BOOL)isHairCategory {
    if ([[self.name substringToIndex:4].uppercaseString isEqualToString:@"HAIR"]) {
        return YES;
    }
    return NO;
}

#pragma mark - AMCTreeNodeProtocol
-(AMCTreeNode *)rootNode {
    return (AMCTreeNode *)self.salon.rootServiceCategory;
}
-(AMCTreeNode *)addChild:(AMCTreeNode *)child {
    if ([child isKindOfClass:[ServiceCategory class]]) {
        ServiceCategory * category = (ServiceCategory*)child;
        [self addSubCategoriesObject:(ServiceCategory*)category];
        return child;
    }
    if ([child isKindOfClass:[Service class]]) {
        Service * service = (Service*)child;
        [self addServiceObject:service];
    }
    return nil;
}
-(AMCTreeNode *)removeChild:(AMCTreeNode *)child {
    if ([child isKindOfClass:[ServiceCategory class]]) {
        ServiceCategory * category = (ServiceCategory*)child;
        [self removeSubCategoriesObject:(ServiceCategory*)category];
        return child;
    }
    if ([child isKindOfClass:[Service class]]) {
        Service * service = (Service*)child;
        [self removeServiceObject:service];
        return child;
    }
    return nil;
}
-(NSInteger)nodesCount {
    return self.subCategories.count;
}
-(NSInteger)leavesCount {
    return self.service.count;
}
-(void)setParentNode:(ServiceCategory*)parentNode {
    self.parent = parentNode;
}
-(ServiceCategory*)parentNode {
    return self.parent;
}
-(NSArray *)leaves {
    return [[self.service allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
}
-(NSArray *)nodes {
    return [[self.subCategories allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
}
-(BOOL)isLeaf {
    return NO;
}

@end
