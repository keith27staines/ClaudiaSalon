//
//  AMCTreeNode.h
//  ClaudiaSalon
//
//  Created by Keith Staines on 19/03/2015.
//  Copyright (c) 2015 ClaudiasSalon. All rights reserved.
//
@class AMCTreeNode;

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol AMCTreeNode <NSObject>
@required
@property (readonly) id<AMCTreeNode> rootNode;
@property id<AMCTreeNode> parentNode;
@property (copy) NSString * name;
@property (readonly) BOOL isLeaf;

-(id<AMCTreeNode>)addChild:(id<AMCTreeNode>)child;
-(id<AMCTreeNode>)removeChild:(id<AMCTreeNode>)child;
-(NSInteger)nodesCount;
-(NSInteger)leavesCount;
@property (readonly,copy) NSArray * leaves;
@property (readonly,copy) NSArray * nodes;
@optional

@end

// AMCTreeNode Interface

@interface AMCTreeNode : NSObject <NSCoding>
-(instancetype)init ;
-(instancetype)initWithName:(NSString*)string isLeaf:(BOOL)isLeaf;
-(instancetype)initWithRepresentedObject:(id<AMCTreeNode>)representedObject;
-(instancetype)initWithRepresentedObject:(id<AMCTreeNode>)representedObject loadSubnodes:(BOOL)loadSubnodes loadLeaves:(BOOL)loadLeaves;
-(instancetype)shallowCopy;
@property (weak) NSManagedObjectContext * moc;
@property (weak,readonly) id<AMCTreeNode>representedObject;
@property (readonly) AMCTreeNode* rootNode;
@property AMCTreeNode* parentNode;
@property (copy) NSString * name;
@property (readonly) BOOL isLeaf;
@property (readonly) NSInteger count;
-(NSInteger)nodesCount;
-(NSInteger)leavesCount;
-(AMCTreeNode*)addChild:(AMCTreeNode*)child;
-(AMCTreeNode*)addChild:(AMCTreeNode *)child updateRepresentedObject:(BOOL)update;
-(AMCTreeNode*)removeChild:(AMCTreeNode*)child;
-(AMCTreeNode*)nodeWithName:(NSString*)string;
-(AMCTreeNode*)leafWithName:(NSString*)string;
-(AMCTreeNode*)mostRecentAncestralDefault ;
-(AMCTreeNode*)mostRecentCommonAncestorWith:(AMCTreeNode*)otherNode;
-(BOOL)containsNodeWithName:(NSString*)string;
-(BOOL)containsLeafWithName:(NSString*)string;
-(BOOL)hasDescendent:(AMCTreeNode*)node;
-(BOOL)hasAncestor:(AMCTreeNode*)node;

@property (copy,readonly) NSArray * allChildren;
-(NSArray*)childNodeNames;
-(NSArray*)childLeafNames;
-(AMCTreeNode*)nodeAtIndex:(NSInteger)index;
-(AMCTreeNode*)leafAtIndex:(NSInteger)index;
-(BOOL)shouldMoveChild:(AMCTreeNode*)child toNewParent:(AMCTreeNode*)proposedParent;


@property (readonly,copy) NSArray * leaves;
@property (readonly,copy) NSArray * nodes;

-(BOOL)contains:(AMCTreeNode*)node;

@end
