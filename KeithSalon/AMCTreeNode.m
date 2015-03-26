//
//  AMCTreeNode.m
//  ClaudiaSalon
//
//  Created by Keith Staines on 19/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import "AMCTreeNode.h"

@interface AMCTreeNode() 
{
    __weak NSManagedObjectContext * _moc;
}
@property (readwrite) AMCTreeNode * parentNode;
@property NSMutableArray * childNodes;
@property NSMutableArray * childLeafs;
@property (readwrite) BOOL isLeaf;
@end

@implementation AMCTreeNode
-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [self init];
    if (self) {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.isLeaf = [aDecoder decodeBoolForKey:@"isLeaf"];
        self.isDeletable = [aDecoder decodeBoolForKey:@"isDeletable"];
        self.childLeafs = [aDecoder decodeObjectForKey:@"childLeafs"];
        self.childNodes = [aDecoder decodeObjectForKey:@"childNodes"];
        self.parentNode = [aDecoder decodeObjectForKey:@"parentNode"];
        self.defaultChildNode = [aDecoder decodeObjectForKey:@"defaultChildNode"];
    }
    return self;
}
-(NSString *)description {
    return [NSString stringWithFormat:@"%@\n%@",self.name,self.childNodes];
}
-(NSManagedObjectContext *)moc {
    return _moc;
}
-(void)setMoc:(NSManagedObjectContext *)moc {
    _moc = moc;
    for (AMCTreeNode * child in self.childNodes) {
        child.moc = moc;
    }
}
-(void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeBool:self.isLeaf forKey:@"isLeaf"];
    [aCoder encodeBool:self.isDeletable forKey:@"isDeletable"];
    [aCoder encodeObject:self.childLeafs forKey:@"childLeafs"];
    [aCoder encodeObject:self.childNodes forKey:@"childNodes"];
    [aCoder encodeObject:self.parentNode forKey:@"parentNode"];
    [aCoder encodeObject:self.defaultChildNode forKey:@"defaultChildNode"];
}
-(instancetype)init {
    return [self initWithName:@"New Group" isLeaf:NO];
}
-(instancetype)initWithName:(NSString*)name isLeaf:(BOOL)isLeaf {
    self = [super init];
    if (self) {
        self.name = [name copy];
        self.childNodes = [NSMutableArray array];
        self.childLeafs = [NSMutableArray array];
        self.isLeaf = isLeaf;
        if (isLeaf) {
            self.isDeletable = NO;
        } else {
            self.isDeletable = YES;
        }
    }
    return self;
}
-(NSArray *)childNodeNames {
    NSMutableArray * names = [NSMutableArray array];
    for (AMCTreeNode * node in self.childNodes) {
        [names addObject:node.name];
    }
    return names;
}
-(NSArray *)childLeafNames {
    NSMutableArray * names = [NSMutableArray array];
    for (AMCTreeNode * node in self.childLeafs) {
        [names addObject:node.name];
    }
    return names;
}
-(BOOL)shouldMoveChild:(AMCTreeNode*)child toNewParent:(AMCTreeNode*)newParent {
    if (!child) {
        return NO;  // Child doesn't exist
    }
    if (!newParent) {
        return NO; // Proposed parent doesn't exist
    }
    if (child == newParent) {
        return NO; // child can't be its own parent
    }
    if (child == child.rootNode) {
        return NO; // Can't move root node
    }
    if (child.parentNode == newParent) {
        return NO; // child is already a child of the proposed parent
    }
    if ([child hasDescendent:newParent]) {
        return NO; // Proposed parent is a descendent of the child
    }
    for (AMCTreeNode * node in self.childNodes) {
        if ([node hasDescendent:child] || [node hasDescendent:newParent]) {
            if (![node shouldMoveChild:child toNewParent:newParent]) {
                return NO;
            }
        }
    }
    return YES;
}
-(instancetype)addChild:(AMCTreeNode*)child {
    if (!child) return nil;
    if ([self contains:child]) return nil;
    [self.childNodes addObject:child];
    child.parentNode = self;
    return child;
}
-(AMCTreeNode *)rootNode {
    AMCTreeNode * node = self;
    while (node.parentNode) {
        node = node.parentNode;
    }
    return node;
}
-(NSArray *)allChildren {
    return [self.childNodes arrayByAddingObjectsFromArray:self.childLeafs];
}
-(AMCTreeNode *)nodeAtIndex:(NSInteger)index {
    return self.childNodes[index];
}
-(NSString *)leafAtIndex:(NSInteger)index {
    return self.childLeafs[index];
}
-(NSInteger)count {
    return self.childNodes.count + self.childLeafs.count;
}
-(NSInteger)nodesCount {
    return self.childNodes.count;
}
-(NSInteger)leavesCount {
    return self.childLeafs.count;
}
-(BOOL)contains:(AMCTreeNode *)node {
    if (self == node) {
        return YES;
    }
    for (AMCTreeNode * other in self.allChildren) {
        if ([other contains:node]) {
            return YES;
        }
    }
    return NO;
}
-(BOOL)containsNodeWithName:(NSString*)string {
    if ([self.name isEqualToString:string]) {
        return YES;
    }
    for (AMCTreeNode * leaf in self.childLeafs) {
        if ([leaf containsNodeWithName:string]) {
            return YES;
        }
    }
    for (AMCTreeNode * node in self.childNodes) {
        if ([node containsNodeWithName:string]) {
            return YES;
        }
    }
    return NO;
}
-(AMCTreeNode*)nodeWithName:(NSString*)string {
    if (!self.isLeaf && [self.name isEqualToString:string]) {
        return self;
    }
    AMCTreeNode * requiredNode;
    for (AMCTreeNode * node in self.childNodes) {
        requiredNode = [node nodeWithName:string];
        if (requiredNode) {
            return requiredNode;
        }
    }
    return nil;
}
-(AMCTreeNode*)leafWithName:(NSString*)string {
    if (self.isLeaf && [self.name isEqualToString:string]) {
        return self;
    }
    AMCTreeNode * requiredLeaf;
    for (AMCTreeNode * leaf in self.childLeafs) {
        requiredLeaf = [leaf leafWithName:string];
        if (requiredLeaf) {
            return requiredLeaf;
        }
    }
    for (AMCTreeNode * node in self.childNodes) {
        requiredLeaf = [node leafWithName:string];
        if (requiredLeaf) {
            return requiredLeaf;
        }
    }
    return nil;
}
-(BOOL)containsLeafWithName:(NSString*)string {
    if (self.isLeaf && [self.name isEqualToString:string]) {
        return YES;
    }
    for (AMCTreeNode * leaf in self.childLeafs) {
        if ([leaf containsLeafWithName:string]) {
            return YES;
        }
    }
    for (AMCTreeNode * node in self.childNodes) {
        if ([node containsLeafWithName:string]) {
            return YES;
        }
    }
    return NO;
}
-(BOOL)hasDescendent:(AMCTreeNode*)node {
    return [node hasAncestor:self];
}
-(BOOL)hasAncestor:(AMCTreeNode *)node {
    if (self == node) return YES;
    if (!self.parentNode) return NO;
    return [self.parentNode hasAncestor:node];
}
-(AMCTreeNode*)removeChild:(AMCTreeNode*)child {
    if (!child) return nil;
    if (![self contains:child]) return nil;
    [self.childNodes removeObject:child];
    child.parentNode = nil;
    return child;
}
-(AMCTreeNode*)mostRecentAncestralDefault {
    if (self.defaultChildNode) {
        return self.defaultChildNode;
    } else {
        return [self.parentNode mostRecentAncestralDefault];
    }
}
-(AMCTreeNode*)mostRecentCommonAncestorWith:(AMCTreeNode*)otherNode {
    if ([self hasDescendent:otherNode]) return self;
    if ([otherNode hasDescendent:self]) return otherNode;
    return [self.parentNode mostRecentCommonAncestorWith:otherNode];
}
-(instancetype)shallowCopy {
    AMCTreeNode * copy = [[self.class alloc] initWithName:self.name isLeaf:self.isLeaf];
    copy.isDeletable = self.isDeletable;
    return copy;
}
@end
