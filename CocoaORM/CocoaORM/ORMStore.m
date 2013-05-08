//
//  ORMStore.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "NSObject+CocoaORM.h"
#import "NSObject+CocoaORMPrivate.h"

#import "ORMEntityDescription.h"
#import "ORMEntitySQLConnector.h"

#import "ORMStore.h"
#import "ORMStore+Private.h"

@interface ORMStore ()
@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic, readonly) FMDatabase *db;

@property (nonatomic, readonly) NSMutableSet *insertedObjects;
@property (nonatomic, readonly) NSMutableSet *changedObjects;
@property (nonatomic, readonly) NSMutableSet *deletedObjects;

@property (nonatomic, readonly) NSMapTable *managedObjects;
@property (nonatomic, readonly) NSMutableSet *managedClasses;
@end

@implementation ORMStore

@synthesize queue = _queue;

- (id)init
{
    return [self initWithSerialQueue:nil];
}

- (id)initWithSerialQueue:(dispatch_queue_t)queue;
{
    self = [super init];
    if (self) {
        
        _insertedObjects = [[NSMutableSet alloc] init];
        _changedObjects = [[NSMutableSet alloc] init];
        _deletedObjects = [[NSMutableSet alloc] init];
        _managedObjects = [NSMapTable strongToWeakObjectsMapTable];
        _managedClasses = [[NSMutableSet alloc] init];
        
        _queue = queue ? queue : dispatch_queue_create("de.tobias-kraentzer.CocoaORM (ORMStore)", DISPATCH_QUEUE_SERIAL);
        
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
                
                ORMEntitySQLConnector *connector = [ORMEntitySQLConnector connectorWithEntityDescription:[[obj class] ORMEntityDescription]];
                
                ORMPrimaryKey pk = [connector insertEntityWithProperties:[obj changedORMValues]
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
                
                ORMEntitySQLConnector *connector = [ORMEntitySQLConnector connectorWithEntityDescription:[[obj class] ORMEntityDescription]];
                
                BOOL success = [connector updateEntityWithPrimaryKey:obj.ORMObjectID.primaryKey
                                                    withProperties:[obj changedORMValues]
                                                        inDatabase:db
                                                             error:&error];
                
                *stop = !success;
                _rollback = !success;
            }];
        }
        
        // Delete Objects in Database
        if (!_rollback) {
            [self.deletedObjects enumerateObjectsUsingBlock:^(NSObject *obj, BOOL *stop) {
                
                ORMEntitySQLConnector *connector = [ORMEntitySQLConnector connectorWithEntityDescription:[[obj class] ORMEntityDescription]];
                
                BOOL success = [connector deleteEntityWithPrimaryKey:obj.ORMObjectID.primaryKey
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
    NSAssert([object ORMObjectID] == nil, @"Object '%@' already managed by a store.", object);
    [self.insertedObjects addObject:object];
}

- (void)deleteObject:(NSObject *)object
{
    NSAssert([self.managedObjects objectForKey:object.ORMObjectID] != nil, @"Object '%@' not managed by this store.", object);
    [self.deletedObjects addObject:object];
}

- (BOOL)existsObjectWithID:(ORMObjectID *)objectID
{
    if ([self.managedObjects objectForKey:objectID]) {
        return YES;
    } else {
        NSError *error = nil;
        
        ORMEntitySQLConnector *connector = [ORMEntitySQLConnector connectorWithEntityDescription:[objectID.ORMClass ORMEntityDescription]];
        
        return [connector existsEntityWithPrimaryKey:objectID.primaryKey
                                        inDatabase:self.db
                                             error:&error];
    }
}

- (id)objectWithID:(ORMObjectID *)objectID
{
    NSObject *object = [self.managedObjects objectForKey:objectID];
    if (object == nil) {
        object = [[objectID.ORMClass alloc] initWithORMObjectID:objectID
                                                        inStore:self
                                                     properties:@{}];
        [self.managedObjects setObject:object forKey:objectID];
    }
    return object;
}

- (void)enumerateObjectsOfClass:(Class)aClass
                     enumerator:(void(^)(id object, BOOL *stop))enumerator
{
    [self enumerateObjectsOfClass:aClass
                matchingCondition:nil
                    withArguments:nil
               fetchingProperties:nil
                       enumerator:enumerator];
}

- (void)enumerateObjectsOfClass:(Class)aClass
              matchingCondition:(NSString *)condition
                  withArguments:(NSDictionary *)arguments
             fetchingProperties:(NSArray *)propertyNames
                     enumerator:(void(^)(id object, BOOL *stop))enumerator
{
    NSError *error = nil;
    ORMEntitySQLConnector *connector = [ORMEntitySQLConnector connectorWithEntityDescription:[aClass ORMEntityDescription]];
    [connector enumerateEntitiesInDatabase:self.db matchingCondition:condition withArguments:arguments fetchingProperties:propertyNames error:&error enumerator:^(ORMPrimaryKey pk, __unsafe_unretained Class klass, NSDictionary *properties, BOOL *stop) {
        ORMObjectID *objectID = [[ORMObjectID alloc] initWithClass:klass primaryKey:pk];
        NSObject *object = [self objectWithID:objectID];
        [[self persistentORMValues] addEntriesFromDictionary:properties];
        enumerator(object, stop);
    }];
}

#pragma mark Apply or Reset Changes

- (void)applyChanges
{
    // Insert
    [self.insertedObjects enumerateObjectsUsingBlock:^(NSObject *obj, BOOL *stop) {
        [obj applyChangedORMValues];
        [self.managedObjects setObject:obj forKey:obj.ORMObjectID];
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
    
    // Delete
    [self.deletedObjects enumerateObjectsUsingBlock:^(NSObject *obj, BOOL *stop) {
        obj.ORMObjectID = nil;
        obj.ORMStore = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSObjectORMValuesDidChangeNotification
                                                      object:obj];
    }];
    [self.deletedObjects removeAllObjects];
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
    
    // Delete
    [self.deletedObjects removeAllObjects];
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
        ORMEntitySQLConnector *connector = [ORMEntitySQLConnector connectorWithEntityDescription:[klass ORMEntityDescription]];
        success = [connector setupSchemataInDatabase:self.db error:error];
        *stop = !success;
    }];
    
    if (success) {
        [self.managedClasses unionSet:classes];
    }
    
    return success;
}

@end



@implementation ORMStore (Private)

@dynamic db;

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
        @autoreleasepool {
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
        }
    };
    
    if (wait) {
        dispatch_sync(self.queue, _block);
    } else {
        dispatch_async(self.queue, _block);
    }
}

@end
