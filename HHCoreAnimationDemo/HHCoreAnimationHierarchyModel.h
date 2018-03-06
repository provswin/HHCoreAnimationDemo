//
//  HHCoreAnimationHierarchyModel.h
//  HHCoreAnimationDemo
//
//  Created by 深圳市秀软科技有限公司 on 05/03/2018.
//  Copyright © 2018 showsoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#define HierarchyModelMake(NAME, HAS_CHILD, CHILD_INDEX) [HHCoreAnimationHierarchyModel hierarchyModelWithName:NAME hasChild:HAS_CHILD childIndex:CHILD_INDEX]
#define HierarchyModelNoChildModelMake(NAME) [HHCoreAnimationHierarchyModel hierarchyModelWithName:NAME hasChild:NO childIndex:nil]

@interface HHCoreAnimationHierarchyModel : NSObject
/**
 模块名称
 */
@property (nonatomic, strong) NSString *name;
/**
 模块是否有子节点
 */
@property (nonatomic, assign, readonly) BOOL hasChild;
/**
 模块子节点所在的数组索引
 */
@property (nonatomic, strong) NSNumber *childIndex;

/**
 HHCoreAnimationHierarchyModel类方法

 @param name 模块名称
 @param hasChild 是否有子节点
 @param childIndex 子节点索引
 @return Model对象
 */
+ (instancetype)hierarchyModelWithName:(NSString *)name hasChild:(BOOL)hasChild childIndex:(NSNumber *)childIndex;

/**
 HHCoreAnimationHierarchyModel

 @param name 模块名称
 @param hasChild 是否有子节点
 @param childIndex 子节点索引
 @return Model对象
 */
- (instancetype)initWithName:(NSString *)name hasChild:(BOOL)hasChild childIndex:(NSNumber *)childIndex;
@end
