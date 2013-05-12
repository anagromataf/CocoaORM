//
//  ORMObject+Private.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 12.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "ORMObject.h"

@class ORMStore;
@class ORMObjectID;

extern NSString * const ORMObjectDidChangeValuesNotification;

@interface ORMObject (Private)

#pragma mark Life-cycle
- (id)initWithEntityDescription:(ORMEntityDescription *)entityDescription;

#pragma mark Managed Object
@property (nonatomic, weak) id managedObject;

#pragma mark Object ID & Store
@property (nonatomic, readwrite) ORMObjectID *objectID;
@property (nonatomic, readwrite) ORMStore *store;

#pragma mark Change Management
@property (nonatomic, readonly) NSMutableDictionary *persistentValues;
- (void)resetChanges;
- (void)applyChanges;

#pragma mark Handle Invocation
- (NSMethodSignature *)methodSignatureForORMSelector:(SEL)aSelector;
- (BOOL)handleInvocation:(NSInvocation *)anInvocation;

@end
