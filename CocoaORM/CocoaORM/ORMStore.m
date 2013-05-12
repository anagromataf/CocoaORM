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

@interface ORMStore ()
@property (nonatomic, readonly) FMDatabase *db;
@property (nonatomic, readonly) dispatch_queue_t queue;

@property (nonatomic, readonly) NSMutableDictionary *entityConnectors;

@property (nonatomic, readonly) NSMutableSet *insertedObjects;
@property (nonatomic, readonly) NSMutableSet *changedObjects;
@property (nonatomic, readonly) NSMutableSet *deletedObjects;

@property (nonatomic, readonly) NSMapTable *managedObjects;
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
        
        _entityConnectors = [[NSMutableDictionary alloc] init];
        
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
                
                ORMEntitySQLConnector *connector = [self connectorWithEntityDescription:ORM.entityDescription];
                
                ORMEntityID eid = [connector insertEntityWithProperties:ORM.changedValues
                                                           intoDatabase:db
                                                                  error:&error];
                
                if (eid) {
                    ORM.objectID = [[ORMObjectID alloc] initWithEntityDescription:ORM.entityDescription entityID:eid];
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
                
                ORMEntitySQLConnector *connector = [self connectorWithEntityDescription:ORM.entityDescription];
                
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
                
                ORMEntitySQLConnector *connector = [self connectorWithEntityDescription:ORM.entityDescription];
                
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

- (id)createObjectWithEntityDescription:(ORMEntityDescription *)entityDescription
{
    ORMObject *ORM = [[ORMObject alloc] initWithEntityDescription:entityDescription];
    id obj = [[entityDescription.managedClass alloc] initWithORMObject:ORM];
    [self.insertedObjects addObject:ORM];
    return obj;
}

- (void)deleteObject:(NSObject *)object
{
    NSAssert([self.managedObjects objectForKey:object.ORM.objectID] != nil, @"Object '%@' not managed by this store.", object);
    [self.deletedObjects addObject:object.ORM];
}

- (id)objectWithID:(ORMObjectID *)objectID
{
    ORMObject *ORM = [self.managedObjects objectForKey:objectID];
    if (ORM == nil) {
        ORM = [[ORMObject alloc] initWithEntityDescription:objectID.entityDescription];
        ORM.store = self;
        ORM.objectID = objectID;
        [self.managedObjects setObject:ORM forKey:objectID];
    }
    
    if (ORM.managedObject) {
        return ORM.managedObject;
    } else {
        return [[ORM.entityDescription.managedClass alloc] initWithORMObject:ORM];
    }
}

- (void)enumerateObjectsOfClass:(Class)aClass
              matchingCondition:(NSString *)condition
                  withArguments:(NSDictionary *)arguments
             fetchingProperties:(NSArray *)propertyNames
                     enumerator:(void(^)(id object, BOOL *stop))enumerator
{
    NSError *error = nil;
    ORMEntitySQLConnector *connector = [self connectorWithEntityDescription:[aClass ORMEntityDescription]];
    [connector enumerateEntitiesInDatabase:self.db matchingCondition:condition withArguments:arguments fetchingProperties:propertyNames error:&error enumerator:^(ORMEntityID eid, __unsafe_unretained Class klass, NSDictionary *properties, BOOL *stop) {
        ORMObjectID *objectID = [[ORMObjectID alloc] initWithEntityDescription:[klass ORMEntityDescription] entityID:eid];
        NSObject *object = [self objectWithID:objectID];
        [[self.ORM persistentValues] addEntriesFromDictionary:properties];
        enumerator(object, stop);
    }];
}

- (void)loadValueWithAttributeDescription:(ORMAttributeDescription *)attributeDescription ofObject:(id)object
{
    NSError *error = nil;
    ORMEntitySQLConnector *connector = [self connectorWithEntityDescription:attributeDescription.entityDescription];
    NSDictionary *properties = [connector propertiesOfEntityWithEntityID:[object ORM].objectID.entityID
                                                              inDatabase:self.db
                                                                   error:&error];
    [[object ORM].persistentValues addEntriesFromDictionary:properties];
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
    __block BOOL success = YES;
    [self.insertedObjects enumerateObjectsUsingBlock:^(ORMObject *ORM, BOOL *stop) {
        
        ORMEntityDescription *entityDescription = ORM.entityDescription;
        ORMEntitySQLConnector *connector = [self.entityConnectors objectForKey:entityDescription.name];
        if (!connector) {
            connector = [[ORMEntitySQLConnector alloc] initWithEntityDescription:entityDescription];
            [self.entityConnectors setObject:connector forKey:entityDescription.name];
            success = [connector setupSchemataInDatabase:self.db error:error];
            *stop = !success;
        }
    }];
    
    return success;
}

- (ORMEntitySQLConnector *)connectorWithEntityDescription:(ORMEntityDescription *)entityDescription
{
    return [self.entityConnectors objectForKey:entityDescription.name];
}

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

