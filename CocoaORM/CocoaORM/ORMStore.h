//
//  ORMStore.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

// Cocoa
#import <Foundation/Foundation.h>

// 3rdParty
#import <FMDB/FMDatabase.h>

@class ORMObject;
@class ORMObjectID;
@class ORMEntityDescription;

typedef void(^ORMStoreTransactionCompletionHalndler)(NSError *error);

@interface ORMStore : NSObject

- (id)initWithSerialQueue:(dispatch_queue_t)queue;

#pragma mark Transactions
- (void)commitTransaction:(ORMStoreTransactionCompletionHalndler(^)(BOOL *rollback))block;
- (void)commitTransactionAndWait:(ORMStoreTransactionCompletionHalndler(^)(BOOL *rollback))block;
- (void)commitTransaction:(ORMStoreTransactionCompletionHalndler(^)(BOOL *rollback))block andWait:(BOOL)wait;

#pragma mark Object Management
- (id)createObjectWithEntityDescription:(ORMEntityDescription *)entityDescription;

- (void)deleteObject:(NSObject *)object;

- (void)loadValueOfObject:(id)object withAttributeDescription:(ORMAttributeDescription *)attributeDescription;

- (void)enumerateObjectsOfClass:(Class)aClass
              matchingCondition:(NSString *)condition
                  withArguments:(NSDictionary *)arguments
             fetchingProperties:(NSArray *)propertyNames
                     enumerator:(void(^)(id object, BOOL *stop))enumerator;

#pragma mark - Private

#pragma mark Database Transaction
- (void)commitTransactionInDatabase:(ORMStoreTransactionCompletionHalndler(^)(FMDatabase *db, BOOL *rollback))block;
- (void)commitTransactionInDatabaseAndWait:(ORMStoreTransactionCompletionHalndler(^)(FMDatabase *db, BOOL *rollback))block;
- (void)commitTransactionInDatabase:(ORMStoreTransactionCompletionHalndler(^)(FMDatabase *db, BOOL *rollback))block andWait:(BOOL)wait;

@end
