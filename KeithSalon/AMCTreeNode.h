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
@optional
@property (readonly,copy) NSArray * leaves;
@property (readonly,copy) NSArray * nodes;
-(id<AMCTreeNode>)nodeAtIndex:(NSInteger)index;
-(NSString*)leafAtIndex:(NSInteger)index;
-(BOOL)contains:(id<AMCTreeNode>)node;
-(BOOL)hasDescendent:(id<AMCTreeNode>)node;
-(BOOL)hasAncestor:(id<AMCTreeNode>)node;
-(BOOL)containsNodeWithName:(NSString*)string;
-(BOOL)containsLeafWithName:(NSString*)string;
-(id<AMCTreeNode>)nodeWithName:(NSString*)string;
-(id<AMCTreeNode>)leafWithName:(NSString*)string;
-(id<AMCTreeNode>)mostRecentAncestralDefault ;
-(id<AMCTreeNode>)mostRecentCommonAncestorWith:(id<AMCTreeNode>)otherNode;
@property (weak) NSManagedObjectContext * moc;
@property (readonly) NSInteger count;
@property (copy,readonly) NSArray * allChildren;
@property BOOL isDeletable;
-(NSArray*)childNodeNames;
-(NSArray*)childLeafNames;
-(BOOL)shouldMoveChild:(id<AMCTreeNode>)child toNewParent:(id<AMCTreeNode>)proposedParent;
@end

// AMCTreeNode Interface
@interface AMCTreeNode : NSObject <AMCTreeNode,NSCoding>
@property (readonly) AMCTreeNode* rootNode;
@property AMCTreeNode* parentNode;

-(instancetype)initWithRepresentedObject:(id<AMCTreeNode>)representedObject;
@property (weak,readonly) id<AMCTreeNode>representedObject;
@property (copy) NSString * name;
-(instancetype)init ;
-(instancetype)initWithName:(NSString*)string isLeaf:(BOOL)isLeaf;
@property (readonly) BOOL isLeaf;
-(instancetype)shallowCopy;
-(AMCTreeNode*)nodeWithName:(NSString*)string;
-(AMCTreeNode*)leafWithName:(NSString*)string;
-(AMCTreeNode*)mostRecentAncestralDefault ;
-(AMCTreeNode*)mostRecentCommonAncestorWith:(id<AMCTreeNode>)otherNode;
@end
