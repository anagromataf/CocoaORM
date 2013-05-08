//
//  CocoaORMDatabaseEnumerateTests.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMDatabaseEnumerateTests.h"

@interface CocoaORMDatabaseEnumerateTests ()
@property (nonatomic, assign) ORMEntityID employeePK;
@property (nonatomic, assign) ORMEntityID personPK;
@end

@implementation CocoaORMDatabaseEnumerateTests

- (void)setUp
{
    [super setUp];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        BOOL success = YES;
        
        success = [self.personConnector setupSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        success = [self.employeeConnector setupSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        success = [self.chefConnector setupSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        // Insert Properties
        
        NSDictionary *properties1 = @{@"firstName":@"Jim",
                                      @"lastName":@"Example",
                                      @"position":@"CEO"};
        
        self.employeePK = [self.employeeConnector insertEntityWithProperties:properties1
                                                              intoDatabase:db
                                                                     error:&error];
        STAssertTrue(self.employeePK != 0, [error localizedDescription]);
        
        
        NSDictionary *properties2 = @{@"firstName":@"John",
                                      @"lastName":@"Example"};
        self.personPK = [self.personConnector insertEntityWithProperties:properties2
                                                          intoDatabase:db
                                                                 error:&error];
        STAssertTrue(self.personPK, [error localizedDescription]);
        
        return ^(NSError *error) {
            STAssertNil(error, [error localizedDescription]);
        };
    }];
}

#pragma mark Test Enumerator

- (void)testEnumerate
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSMutableSet *primaryKeys = [[NSMutableSet alloc] init];
        NSMutableSet *classes = [[NSMutableSet alloc] init];
        
        NSError *error = nil;
        BOOL success = [self.personConnector enumerateEntitiesInDatabase:db
                                                                 error:&error
                                                            enumerator:^(ORMEntityID eid, __unsafe_unretained Class klass, BOOL *stop) {
                                                                [primaryKeys addObject:@(eid)];
                                                                [classes addObject:klass];
                                                            }];
        STAssertTrue(success, [error localizedDescription]);
        
        NSSet *_p = [NSSet setWithObjects:@(self.employeePK), @(self.personPK), nil];
        STAssertEqualObjects(primaryKeys, _p, nil);
        
        NSSet *_c = [NSSet setWithObjects:[Employee class], [Person class], nil];
        STAssertEqualObjects(classes, _c, nil);
        
        return nil;
    }];
}

- (void)testEnumerateAndStop
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSMutableSet *primaryKeys = [[NSMutableSet alloc] init];

        NSError *error = nil;
        BOOL success = [self.personConnector enumerateEntitiesInDatabase:db
                                                                 error:&error
                                                            enumerator:^(ORMEntityID eid, __unsafe_unretained Class klass, BOOL *stop) {
                                                                [primaryKeys addObject:@(eid)];
                                                                *stop = YES;
                                                            }];
        STAssertTrue(success, [error localizedDescription]);
        STAssertEquals([primaryKeys count], (NSUInteger)1, nil);
        return nil;
    }];
}


- (void)testEnumerateWithProperties
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSMutableSet *primaryKeys = [[NSMutableSet alloc] init];
        NSMutableSet *classes = [[NSMutableSet alloc] init];
        
        NSError *error = nil;
        BOOL success = [self.personConnector enumerateEntitiesInDatabase:db
                                                    fetchingProperties:@[@"lastName"]
                                                                 error:&error
                                                            enumerator:^(ORMEntityID eid, __unsafe_unretained Class klass, NSDictionary *properties, BOOL *stop) {
                                                                [primaryKeys addObject:@(eid)];
                                                                [classes addObject:klass];
                                                                STAssertEqualObjects(properties, @{@"lastName":@"Example"}, nil);
                                                            }];
        STAssertTrue(success, [error localizedDescription]);
        
        NSSet *_p = [NSSet setWithObjects:@(self.employeePK), @(self.personPK), nil];
        STAssertEqualObjects(primaryKeys, _p, nil);
        
        NSSet *_c = [NSSet setWithObjects:[Employee class], [Person class], nil];
        STAssertEqualObjects(classes, _c, nil);
        
        return nil;
    }];
}

- (void)testEnumerateWithCondition
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        NSError *error = nil;
        ORMEntityID eid = [self.personConnector insertEntityWithProperties:@{@"firstName":@"John",  @"lastName":@"Tester"}
                                                             intoDatabase:db
                                                                    error:&error];
        STAssertTrue(eid != 0, [error localizedDescription]);
        return nil;
    }];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        BOOL success = [self.personConnector enumerateEntitiesInDatabase:db
                                                     matchingCondition:@"lastName = :lastName"
                                                         withArguments:@{@"lastName":@"Example"}
                                                    fetchingProperties:@[@"lastName"]
                                                                 error:&error
                                                            enumerator:^(ORMEntityID eid, __unsafe_unretained Class klass, NSDictionary *properties, BOOL *stop) {
                                                                STAssertEqualObjects(properties, @{@"lastName":@"Example"}, nil);
                                                            }];
        STAssertTrue(success, [error localizedDescription]);
        
        return nil;
    }];
}

@end
