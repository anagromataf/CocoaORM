//
//  ORMObject.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 08.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

// CocoaORM
#import "ORMObjectID.h"
#import "ORMStore.h"

extern NSString * const ORMObjectDidChangeValuesNotification;

@interface ORMObject : NSObject

#pragma mark Life-cycle
- (id)initWithEntityDescription:(ORMEntityDescription *)entityDescription;

#pragma mark Managed Object
@property (nonatomic, readonly) id managedObject;

#pragma mark Entity Description
@property (nonatomic, readonly) ORMEntityDescription *entityDescription;

#pragma mark Object ID & Store
@property (nonatomic, readwrite) ORMObjectID *objectID;
@property (nonatomic, readwrite) ORMStore *store;

#pragma mark Values
@property (nonatomic, strong) NSMutableDictionary *persistentValues;
@property (nonatomic, readonly) NSDictionary *changedValues;

- (void)resetChanges;
- (void)applyChanges;

#pragma mark Handle Invocation
- (NSMethodSignature *)methodSignatureForORMSelector:(SEL)aSelector;
- (BOOL)handleInvocation:(NSInvocation *)anInvocation;

@end
