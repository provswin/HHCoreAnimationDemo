//
//  HHCoreAnimationHierarchyModel.m
//  HHCoreAnimationDemo
//
//  Created by 深圳市秀软科技有限公司 on 03/03/2018.
//  Copyright © 2018 showsoft. All rights reserved.
//

#import "HHCoreAnimationHierarchyModel.h"
@interface HHCoreAnimationHierarchyModel ()
@property (nonatomic, assign, readwrite) BOOL hasChild;
@end

@implementation HHCoreAnimationHierarchyModel
+ (instancetype)hierarchyModelWithName:(NSString *)name hasChild:(BOOL)hasChild childIndex:(NSNumber *)childIndex {
    HHCoreAnimationHierarchyModel *model = [[HHCoreAnimationHierarchyModel alloc] initWithName:name hasChild:hasChild childIndex:childIndex];
    return model;
}

/**
 init方法：禁止直接访问init方法

 @return 抛出异常
 */
- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Use initWithName:hasChild:childIndex: instead." userInfo:nil];
}

- (instancetype)initWithName:(NSString *)name hasChild:(BOOL)hasChild childIndex:(NSNumber *)childIndex {
    self = [super init];
    if (self) {
        _hasChild = hasChild;
        _name = name;
        _childIndex = childIndex;
    }
    return self;
}
@end

