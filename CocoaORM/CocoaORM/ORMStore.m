//
//  ORMStore.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "ORMStore.h"
#import "ORMStore+Private.h"

@interface ORMStore ()
@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic, readonly) FMDatabase *db;
@end

@implementation ORMStore

@synthesize queue = _queue;

- (id)init
{
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("de.tobias-kraentzer.CocoaORM (ORMStore)", DISPATCH_QUEUE_SERIAL);
        
        _db = [[FMDatabase alloc] initWithPath:nil];
        BOOL success = [_db open];
        NSAssert(success, @"Coud not open database: %@", [_db.lastError localizedDescription]);
        
        // Enable Foreign Key Support
        success = [_db executeUpdate:@"PRAGMA foreign_keys = ON"];
        NSAssert(success, @"Coud not enable foreign key support: %@", [_db.lastError localizedDescription]);
    }
    return self;
}

#pragma mark Transactions

- (void)commitTransaction:(ORMStoreTransactionCompletionHalndler(^)(BOOL *rollback))block
{
    [self commitTransaction:block andWait:NO];
}

- (void)commitTransactionAndWait:(ORMStoreTransactionCompletionHalndler(^)(BOOL *rollback))block
{
    [self commitTransaction:block andWait:YES];
}

- (void)commitTransaction:(ORMStoreTransactionCompletionHalndler(^)(BOOL *rollback))block andWait:(BOOL)wait
{
    [self commitTransactionInDatabase:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        BOOL _rollback = NO;
        ORMStoreTransactionCompletionHalndler completionHalndler = block(&_rollback);
        
        __block NSError *error = nil;
        *rollback = _rollback;
        
        return ^(NSError *_error) {
            
            if (completionHalndler) {
                completionHalndler(error);
            }
        };
        
    } andWait:wait];
}

@end



@implementation ORMStore (Private)

#pragma mark Database Transaction

- (void)commitTransactionInDatabase:(ORMStoreTransactionCompletionHalndler(^)(FMDatabase *db, BOOL *rollback))block;
{
    [self commitTransactionInDatabase:block andWait:NO];
}

- (void)commitTransactionInDatabaseAndWait:(ORMStoreTransactionCompletionHalndler(^)(FMDatabase *db, BOOL *rollback))block;
{
    [self commitTransactionInDatabase:block andWait:YES];
}

- (void)commitTransactionInDatabase:(ORMStoreTransactionCompletionHalndler(^)(FMDatabase *db, BOOL *rollback))block andWait:(BOOL)wait
{
    void(^_block)() = ^{
        
        // Begin Transaction
        
        [self.db beginTransaction];
        
        BOOL rollback = NO;
        ORMStoreTransactionCompletionHalndler completionHalndler = block(self.db, &rollback);
        
        BOOL success = YES;
        
        if (rollback) {
            // Rollback Transaction
            success = [self.db rollback];
        } else {
            // Commit Transaction
            success = [self.db commit];
        }
        
        if (completionHalndler) {
            if (!success) {
                completionHalndler(self.db.lastError);
            } else {
                completionHalndler(nil);
            }
        }
    };
    
    if (wait) {
        dispatch_sync(self.queue, _block);
    } else {
        dispatch_async(self.queue, _block);
    }
}

@end
