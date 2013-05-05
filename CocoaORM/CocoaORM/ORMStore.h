//
//  ORMStore.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

// Cocoa
#import <Foundation/Foundation.h>

// CocoaORM
#import "ORMObjectID.h"

typedef void(^ORMStoreTransactionCompletionHalndler)(NSError *error);

@interface ORMStore : NSObject

- (id)initWithSerialQueue:(dispatch_queue_t)queue;

#pragma mark Transactions
- (void)commitTransaction:(ORMStoreTransactionCompletionHalndler(^)(BOOL *rollback))block;
- (void)commitTransactionAndWait:(ORMStoreTransactionCompletionHalndler(^)(BOOL *rollback))block;
- (void)commitTransaction:(ORMStoreTransactionCompletionHalndler(^)(BOOL *rollback))block andWait:(BOOL)wait;

#pragma mark Object Management
- (void)insertObject:(NSObject *)object;
- (void)deleteObject:(NSObject *)object;

- (BOOL)existsObjectWithID:(ORMObjectID *)objectID;

- (id)objectWithID:(ORMObjectID *)objectID;

- (void)enumerateObjectsOfClass:(Class)aClass
                     enumerator:(void(^)(id object, BOOL *stop))enumerator;

- (void)enumerateObjectsOfClass:(Class)aClass
              matchingCondition:(NSString *)condition
                  withArguments:(NSDictionary *)arguments
             fetchingProperties:(NSArray *)propertyNames
                     enumerator:(void(^)(id object, BOOL *stop))enumerator;

@end
