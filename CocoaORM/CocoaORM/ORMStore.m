//
//  ORMStore.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "NSObject+CocoaORM.h"

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
        
        _managedClasses = [[NSMutableSet alloc] init];
        
        _managedObjects = [NSMapTable strongToWeakObjectsMapTable];
        
        _insertedObjects = [[NSMutableSet alloc] init];
        _changedObjects = [[NSMutableSet alloc] init];
        _deletedObjects = [[NSMutableSet alloc] init];
        
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
            [self.insertedObjects enumerateObjectsUsingBlock:^(ORMObject *ORM, BOOL *stop) {
                
                ORMEntitySQLConnector *connector = [ORMEntitySQLConnector connectorWithEntityDescription:ORM.entityDescription];
                
                ORMEntityID eid = [connector insertEntityWithProperties:ORM.changedValues
                                                          intoDatabase:db
                                                                 error:&error];
                
                if (eid) {
                    ORM.objectID = [[ORMObjectID alloc] initWithClass:ORM.entityDescription.managedClass primaryKey:eid];
                    ORM.store = self;
                } else {
                    *stop = YES;
                    _rollback = YES;
                }
            }];
        }
        
        // Update Objects in Database
        if (!_rollback) {
            [self.changedObjects enumerateObjectsUsingBlock:^(ORMObject *ORM, BOOL *stop) {
                
                ORMEntitySQLConnector *connector = [ORMEntitySQLConnector connectorWithEntityDescription:ORM.entityDescription];
                
                BOOL success = [connector updateEntityWithEntityID:ORM.objectID.entityID
                                                    withProperties:ORM.changedValues
                                                        inDatabase:db
                                                             error:&error];
                
                *stop = !success;
                _rollback = !success;
            }];
        }
        
        // Delete Objects in Database
        if (!_rollback) {
            [self.deletedObjects enumerateObjectsUsingBlock:^(ORMObject *ORM, BOOL *stop) {
                
                ORMEntitySQLConnector *connector = [ORMEntitySQLConnector connectorWithEntityDescription:ORM.entityDescription];
                
                BOOL success = [connector deleteEntityWithEntityID:ORM.objectID.entityID
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
    NSAssert(object.ORM.objectID == nil, @"Object '%@' already managed by a store.", object);
    [self.insertedObjects addObject:object.ORM];
}

- (void)deleteObject:(NSObject *)object
{
    NSAssert([self.managedObjects objectForKey:object.ORM.objectID] != nil, @"Object '%@' not managed by this store.", object);
    [self.deletedObjects addObject:object.ORM];
}

- (BOOL)existsObjectWithID:(ORMObjectID *)objectID
{
    if ([self.managedObjects objectForKey:objectID]) {
        return YES;
    } else {
        NSError *error = nil;
        
        ORMEntitySQLConnector *connector = [ORMEntitySQLConnector connectorWithEntityDescription:[objectID.ORMClass ORMEntityDescription]];
        
        return [connector existsEntityWithEntityID:objectID.entityID
                                        inDatabase:self.db
                                             error:&error];
    }
}

- (id)objectWithID:(ORMObjectID *)objectID
{
    ORMObject *ORM = [self.managedObjects objectForKey:objectID];
    if (ORM == nil) {
        ORM = [[ORMObject alloc] initWithEntityDescription:[objectID.ORMClass ORMEntityDescription]];
        ORM.store = self;
        ORM.objectID = objectID;
        [self.managedObjects setObject:ORM forKey:objectID];
    }
    return [[ORM.entityDescription.managedClass alloc] initWithORMObject:ORM];
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
    [connector enumerateEntitiesInDatabase:self.db matchingCondition:condition withArguments:arguments fetchingProperties:propertyNames error:&error enumerator:^(ORMEntityID eid, __unsafe_unretained Class klass, NSDictionary *properties, BOOL *stop) {
        ORMObjectID *objectID = [[ORMObjectID alloc] initWithClass:klass primaryKey:eid];
        NSObject *object = [self objectWithID:objectID];
        [[self.ORM persistentValues] addEntriesFromDictionary:properties];
        enumerator(object, stop);
    }];
}

#pragma mark Apply or Reset Changes

- (void)applyChanges
{
    // Insert
    [self.insertedObjects enumerateObjectsUsingBlock:^(ORMObject *ORM, BOOL *stop) {
        [ORM applyChanges];
        [self.managedObjects setObject:ORM forKey:ORM.objectID];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(objectORMValuesDidChange:)
                                                     name:ORMObjectDidChangeValuesNotification
                                                   object:ORM];
    }];
    [self.insertedObjects removeAllObjects];
    
    // Update
    [self.changedObjects enumerateObjectsUsingBlock:^(ORMObject *ORM, BOOL *stop) {
        [ORM applyChanges];
    }];
    [self.changedObjects removeAllObjects];
    
    // Delete
    [self.deletedObjects enumerateObjectsUsingBlock:^(ORMObject *ORM, BOOL *stop) {
        ORM.objectID = nil;
        ORM.store = nil;
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:ORMObjectDidChangeValuesNotification
                                                      object:ORM];
    }];
    [self.deletedObjects removeAllObjects];
}

- (void)resetChanges
{
    // Insert
    [self.insertedObjects enumerateObjectsUsingBlock:^(ORMObject *ORM, BOOL *stop) {
        [ORM resetChanges];
        ORM.objectID = nil;
        ORM.store = nil;
    }];
    [self.insertedObjects removeAllObjects];
    
    // Update
    [self.changedObjects enumerateObjectsUsingBlock:^(ORMObject *ORM, BOOL *stop) {
        [ORM resetChanges];
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
    [self.insertedObjects enumerateObjectsUsingBlock:^(ORMObject *ORM, BOOL *stop) {
        if (![self.managedClasses containsObject:ORM.entityDescription.managedClass]) {
            [classes addObject:ORM.entityDescription.managedClass];
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
