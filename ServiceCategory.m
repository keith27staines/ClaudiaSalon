//
//  ServiceCategory.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 25/01/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

#import "ServiceCategory.h"
#import "Note.h"
#import "Salon.h"
#import "Service.h"

#import "ServiceCategory.h"
#import "Service.h"

@implementation ServiceCategory
+(NSManagedObject*)createObjectInMoc:(NSManagedObjectContext*)moc
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
    if (self.parent.parent == nil) {
        if ([[self.name substringToIndex:4].uppercaseString isEqualToString:@"HAIR"]) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return [self.parent isHairCategory];
    }
}
-(BOOL)isBeautyCategory {
    if (self.parent.parent == nil) {
        if ([[self.name substringToIndex:4].uppercaseString isEqualToString:@"BEAU"]) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return [self.parent isBeautyCategory];
    }
}

#pragma mark - AMCTreeNodeProtocol
-(ServiceCategory*)rootNode {
    return self.salon.rootServiceCategory;
}
-(void)setParentNode:(ServiceCategory*)parentNode {
    self.parent = parentNode;
}
-(ServiceCategory*)parentNode {
    return self.parent;
}
-(BOOL)isLeaf {
    return NO;
}
-(BOOL)isSystemNode {
    return self.isSystemCategory.boolValue;
}
-(id<AMCTreeNode>)addChild:(id<AMCTreeNode>)child {
    if ([child isKindOfClass:[ServiceCategory class]]) {
        ServiceCategory * category = (ServiceCategory*)child;
        [self addSubCategoriesObject:category];
        return child;
    }
    if ([child isKindOfClass:[Service class]]) {
        Service * service = (Service*)child;
        [self addServiceObject:service];
    }
    return nil;
}
-(id<AMCTreeNode>)removeChild:(id<AMCTreeNode>)child {
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

-(NSArray *)leaves {
    return [[self.service allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
}
-(NSArray *)nodes {
    return [[self.subCategories allObjects] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
}


@end

