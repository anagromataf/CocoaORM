//
//  ORMStore.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

// Cocoa
#import <Foundation/Foundation.h>

@class ORMObject;
@class ORMObjectID;
@class ORMEntityDescription;

typedef void(^ORMStoreTransactionCompletionHandler)(NSError *error);

@interface ORMStore : NSObject

#pragma mark Life-cycle
- (id)initWithSerialQueue:(dispatch_queue_t)queue;

#pragma mark Transactions
- (void)commitTransaction:(ORMStoreTransactionCompletionHandler(^)(BOOL *rollback))block;
- (void)commitTransactionAndWait:(ORMStoreTransactionCompletionHandler(^)(BOOL *rollback))block;

#pragma mark Object Life-cycle
- (id)createObjectWithEntityDescription:(ORMEntityDescription *)entityDescription;
- (void)deleteObject:(NSObject *)object;

#pragma mark Object Property Loading
- (void)loadValueWithAttributeDescription:(ORMAttributeDescription *)attributeDescription ofObject:(id)object;

#pragma mark Object Enumeration
- (void)enumerateObjectsOfClass:(Class)aClass
              matchingCondition:(NSString *)condition
                  withArguments:(NSDictionary *)arguments
             fetchingProperties:(NSArray *)propertyNames
                     enumerator:(void(^)(id object, BOOL *stop))enumerator;

@end
