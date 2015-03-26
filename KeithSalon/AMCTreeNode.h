//
//  AMCTreeNode.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 19/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface AMCTreeNode : NSObject <NSCoding>
@property (weak) NSManagedObjectContext * moc;
@property (readonly) AMCTreeNode * parentNode;
@property (readonly) NSInteger count;
@property (copy,readonly) NSArray * allChildren;
@property (copy) NSString * name;
-(instancetype)addChild:(AMCTreeNode*)child;
-(AMCTreeNode*)removeChild:(AMCTreeNode*)child;
-(instancetype)init ;
-(instancetype)initWithName:(NSString*)string isLeaf:(BOOL)isLeaf;
-(NSInteger)nodesCount;
-(NSInteger)leavesCount;
-(AMCTreeNode*)nodeAtIndex:(NSInteger)index;
-(NSString*)leafAtIndex:(NSInteger)index;
@property BOOL isDeletable;
-(BOOL)contains:(AMCTreeNode*)node;
-(BOOL)hasDescendent:(AMCTreeNode*)node;
-(BOOL)hasAncestor:(AMCTreeNode*)node;
@property (readonly) BOOL isLeaf;
@property AMCTreeNode * defaultChildNode;
-(BOOL)containsNodeWithName:(NSString*)string;
-(BOOL)containsLeafWithName:(NSString*)string;
-(AMCTreeNode*)nodeWithName:(NSString*)string;
-(AMCTreeNode*)leafWithName:(NSString*)string;
-(BOOL)shouldMoveChild:(AMCTreeNode*)child toNewParent:(AMCTreeNode*)newParent;
-(AMCTreeNode*)mostRecentAncestralDefault ;
-(AMCTreeNode*)rootNode;
-(AMCTreeNode*)mostRecentCommonAncestorWith:(AMCTreeNode*)otherNode;
-(instancetype)shallowCopy;
-(NSArray*)childNodeNames;
-(NSArray*)childLeafNames;
@end
