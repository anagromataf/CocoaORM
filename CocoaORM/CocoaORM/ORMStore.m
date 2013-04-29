//
//  ORMStore.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "NSObject+CocoaORM.h"
#import "NSObject+CocoaORMPrivate.h"

#import "ORMStore.h"
#import "ORMStore+Private.h"

@interface ORMStore ()
@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic, readonly) FMDatabase *db;

@property (nonatomic, readonly) NSMutableSet *insertedObjects;
@property (nonatomic, readonly) NSMutableSet *changedObjects;

@property (nonatomic, readonly) NSMutableSet *managedObjects;
@property (nonatomic, readonly) NSMutableSet *managedClasses;
@end

@implementation ORMStore

@synthesize queue = _queue;

- (id)init
{
    self = [super init];
    if (self) {
        
        _insertedObjects = [[NSMutableSet alloc] init];
        _changedObjects = [[NSMutableSet alloc] init];
        _managedObjects = [[NSMutableSet alloc] init];
        _managedClasses = [[NSMutableSet alloc] init];
        
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
        
        __block BOOL _rollback = NO;
        __block NSError *error = nil;
        
        ORMStoreTransactionCompletionHalndler completionHalndler = block(&_rollback);
        
        // Setup Schemata
        if (!_rollback) {
            if (![self setupSchemataInDatabase:db error:&error]) {
                _rollback = YES;
            }
        }
        
        // Insert Objects into Database
        if (!_rollback) {
            [self.insertedObjects enumerateObjectsUsingBlock:^(NSObject *obj, BOOL *stop) {
                
                ORMPrimaryKey pk = [[obj class] insertORMObjectProperties:[obj changedORMValues]
                                                             intoDatabase:db
                                                                    error:&error];
                if (pk) {
                    obj.ORMObjectID = [[ORMObjectID alloc] initWithClass:[obj class] primaryKey:pk];
                    obj.ORMStore = self;
                } else {
                    *stop = YES;
                    _rollback = YES;
                }
            }];
        }
        
        // Update Objects in Database
        if (!_rollback) {
            [self.changedObjects enumerateObjectsUsingBlock:^(NSObject *obj, BOOL *stop) {
                
                BOOL success = [[obj class] updateORMObjectWithPrimaryKey:obj.ORMObjectID.primaryKey
                                                           withProperties:[obj changedORMValues]
                                                               inDatabase:db
                                                                    error:&error];
                
                *stop = !success;
                _rollback = !success;
            }];
        }
        
        *rollback = _rollback;
        
        return ^(NSError *_error) {
            
            if (_error) {
                [self resetChanges];
                if (completionHalndler) {
                    completionHalndler(_error);
                }
            } else {
                if (_rollback) {
                    [self resetChanges];
                } else {
                    [self applyChanges];
                }
                
                if (completionHalndler) {
                    completionHalndler(error);
                }
            }
        };
        
    } andWait:wait];
}

#pragma mark Object Management

- (void)insertObject:(NSObject *)object
{
    NSAssert([self.managedObjects containsObject:object] == NO, @"Object '%@' already managed by this store.", object);
    [self.insertedObjects addObject:object];
}

#pragma Apply or Reset Changes

- (void)applyChanges
{
    // Insert
    [self.insertedObjects enumerateObjectsUsingBlock:^(NSObject *obj, BOOL *stop) {
        [obj applyChangedORMValues];
        [self.managedObjects addObject:obj];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(objectORMValuesDidChange:)
                                                     name:NSObjectORMValuesDidChangeNotification
                                                   object:obj];
    }];
    [self.insertedObjects removeAllObjects];

    // Update
    [self.changedObjects enumerateObjectsUsingBlock:^(NSObject *obj, BOOL *stop) {
        [obj applyChangedORMValues];
    }];
    [self.changedObjects removeAllObjects];
}

- (void)resetChanges
{
    // Insert
    [self.insertedObjects enumerateObjectsUsingBlock:^(NSObject *obj, BOOL *stop) {
        [obj resetChangedORMValues];
        obj.ORMObjectID = nil;
        obj.ORMStore = nil;
    }];
    [self.insertedObjects removeAllObjects];
    
    // Update
    [self.changedObjects enumerateObjectsUsingBlock:^(NSObject *obj, BOOL *stop) {
        [obj resetChangedORMValues];
    }];
    [self.changedObjects removeAllObjects];
}

#pragma mark Handle Object Change Notification

- (void)objectORMValuesDidChange:(NSNotification *)aNotification
{
    [self.changedObjects addObject:aNotification.object];
}

#pragma mark Setup Schemata

- (BOOL)setupSchemataInDatabase:(FMDatabase *)database error:(NSError **)error
{
    NSMutableSet *classes = [[NSMutableSet alloc] init];
    [self.insertedObjects enumerateObjectsUsingBlock:^(NSObject *obj, BOOL *stop) {
        if (![self.managedClasses containsObject:[obj class]]) {
            [classes addObject:[obj class]];
        }
    }];
    
    __block BOOL success = YES;
    [classes enumerateObjectsUsingBlock:^(Class klass, BOOL *stop) {
        NSAssert([klass isORMClass], @"Class %@ is not managed by CocoaORM.", klass);
        success = [klass setupORMSchemataInDatabase:self.db error:error];
        *stop = !success;
    }];
    
    if (success) {
        [self.managedClasses unionSet:classes];
    }
    
    return success;
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
