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

#pragma mark Transactions
- (void)commitTransaction:(ORMStoreTransactionCompletionHalndler(^)(BOOL *rollback))block;
- (void)commitTransactionAndWait:(ORMStoreTransactionCompletionHalndler(^)(BOOL *rollback))block;
- (void)commitTransaction:(ORMStoreTransactionCompletionHalndler(^)(BOOL *rollback))block andWait:(BOOL)wait;

#pragma mark Object Management
- (void)insertObject:(NSObject *)object;
- (void)deleteObject:(NSObject *)object;

- (BOOL)existsObjectWithID:(ORMObjectID *)objectID;

- (id)objectWithID:(ORMObjectID *)objectID;

@end
