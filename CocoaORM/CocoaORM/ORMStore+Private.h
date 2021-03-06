//
//  ORMStore+Private.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 13.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

// 3rdParty
#import <FMDB/FMDatabase.h>

#import "ORMStore.h"

@interface ORMStore (Private)

#pragma mark Database Transaction
- (void)commitTransactionInDatabase:(ORMStoreTransactionCompletionHandler(^)(FMDatabase *db, BOOL *rollback))block;
- (void)commitTransactionInDatabaseAndWait:(ORMStoreTransactionCompletionHandler(^)(FMDatabase *db, BOOL *rollback))block;
- (void)commitTransactionInDatabase:(ORMStoreTransactionCompletionHandler(^)(FMDatabase *db, BOOL *rollback))block andWait:(BOOL)wait;

@end
