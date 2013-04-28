//
//  ORMStore+Private.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

// 3rdParty
#import <FMDB/FMDatabase.h>

#import "ORMStore.h"

@interface ORMStore (Private)

#pragma mark Database Transaction
- (void)commitTransactionInDatabase:(ORMStoreTransactionCompletionHalndler(^)(FMDatabase *db, BOOL *rollback))block;
- (void)commitTransactionInDatabaseAndWait:(ORMStoreTransactionCompletionHalndler(^)(FMDatabase *db, BOOL *rollback))block;
- (void)commitTransactionInDatabase:(ORMStoreTransactionCompletionHalndler(^)(FMDatabase *db, BOOL *rollback))block andWait:(BOOL)wait;

@end
