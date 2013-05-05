//
//  CocoaORMDatabasePropertyTests.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMDatabasePropertyTests.h"

@implementation CocoaORMDatabasePropertyTests

- (void)setUp
{
    [super setUp];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        BOOL success;
        NSError *error = nil;

        success = [self.personMapping setupSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        success = [self.employeeMapping setupSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        success = [self.chefMapping setupSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        return nil;
    }];
}

#pragma mark Test Insert, Update & Delete Properties

- (void)testInsertProperties
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        
        // Insert Properties
        
        NSDictionary *properties = @{@"firstName":@"Jim",
                                     @"lastName":@"Example",
                                     @"position":@"CEO",
                                     @"employeeID":@(12)};
        
        ORMPrimaryKey pk = [self.employeeMapping insertEntityWithProperties:properties
                                                               intoDatabase:db
                                                                      error:&error];
        STAssertTrue(pk != 0, [error localizedDescription]);
        
        return ^(NSError *error) {
            STAssertNil(error, [error localizedDescription]);
            
            FMResultSet *result = nil;
            
            result = [db executeQuery:@"SELECT * FROM Person WHERE _id = :_id" withParameterDictionary:@{@"_id":@(pk)}];
            STAssertNotNil(result, [db.lastError localizedDescription]);
            
            STAssertEquals([result columnCount], 4, nil);
            
            STAssertTrue([result next], nil);
            STAssertEqualObjects([result objectForColumnName:@"_id"], @(pk), nil);
            STAssertEqualObjects([result objectForColumnName:@"_class"], NSStringFromClass([Employee class]), nil);
            STAssertEqualObjects([result objectForColumnName:@"firstName"], @"Jim", nil);
            STAssertEqualObjects([result objectForColumnName:@"lastName"], @"Example", nil);
            
            STAssertFalse([result next], nil);
            
            
            result = [db executeQuery:@"SELECT * FROM Employee WHERE _id = :_id" withParameterDictionary:@{@"_id":@(pk)}];
            STAssertNotNil(result, [db.lastError localizedDescription]);
            
            STAssertEquals([result columnCount], 4, nil);
            
            STAssertTrue([result next], nil);
            STAssertEqualObjects([result objectForColumnName:@"_id"], @(pk), nil);
            STAssertEqualObjects([result objectForColumnName:@"position"], @"CEO", nil);
            STAssertEqualObjects([result objectForColumnName:@"fired"], [NSNull null], nil);
            STAssertEqualObjects([result objectForColumnName:@"employeeID"], @(12), nil);
            
            STAssertFalse([result next], nil);
        };
    }];
}

- (void)testUpdateProperties
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        BOOL success = YES;
        
        // Insert Properties
        
        NSDictionary *properties = @{
                                     @"firstName":@"Jim",
                                     @"lastName":@"Example",
                                     @"position":@"CEO"
                                     };
        
        ORMPrimaryKey pk = [self.employeeMapping insertEntityWithProperties:properties
                                                               intoDatabase:db
                                                                      error:&error];
        STAssertTrue(pk != 0, [error localizedDescription]);
        
        // Update Properties
        success = [self.employeeMapping updateEntityWithPrimaryKey:pk
                                                    withProperties:@{@"firstName":@"John", @"position":@"CTO"}
                                                        inDatabase:db
                                                             error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        return ^(NSError *error) {
            STAssertNil(error, [error localizedDescription]);
            
            FMResultSet *result = nil;
            
            result = [db executeQuery:@"SELECT * FROM Person NATURAL JOIN Employee WHERE _id = :_id" withParameterDictionary:@{@"_id":@(pk)}];
            STAssertNotNil(result, [db.lastError localizedDescription]);
            
            STAssertTrue([result next], nil);
            STAssertEqualObjects([result objectForColumnName:@"firstName"], @"John", nil);
            STAssertEqualObjects([result objectForColumnName:@"position"], @"CTO", nil);
        };
    }];
}

- (void)testDeleteProperties
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        BOOL success = YES;
        
        // Insert Properties
        
        NSDictionary *properties = @{@"firstName":@"Jim",
                                     @"lastName":@"Example",
                                     @"position":@"CEO"
                                     };
        
        ORMPrimaryKey pk = [self.employeeMapping insertEntityWithProperties:properties
                                                               intoDatabase:db
                                                                      error:&error];
        STAssertTrue(pk != 0, [error localizedDescription]);
        
        // Delete Properties
        
        success = [self.employeeMapping deleteEntityWithPrimaryKey:pk
                                                        inDatabase:db
                                                             error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        return ^(NSError *error) {
            STAssertNil(error, [error localizedDescription]);
            
            FMResultSet *result = nil;
            
            result = [db executeQuery:@"SELECT * FROM Person WHERE _id = :_id" withParameterDictionary:@{@"_id":@(pk)}];
            STAssertNotNil(result, [db.lastError localizedDescription]);
            STAssertFalse([result next], nil);
            
            result = [db executeQuery:@"SELECT * FROM Employee WHERE _id = :_id" withParameterDictionary:@{@"_id":@(pk)}];
            STAssertNotNil(result, [db.lastError localizedDescription]);
            STAssertFalse([result next], nil);
        };
    }];
}
#pragma mark Test Get Properties

- (void)testGetProperties
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        
        // Insert Properties

        NSDictionary *properties1 = @{@"firstName":@"John",
                                      @"lastName":@"Example",
                                      @"position":@"CTO",
                                      @"employeeID":@(13)};
        ORMPrimaryKey pk1 = [self.employeeMapping insertEntityWithProperties:properties1
                                                                intoDatabase:db
                                                                       error:&error];
        STAssertTrue(pk1 != 0, [error localizedDescription]);
        
        NSDictionary *properties2 = @{@"firstName":@"Jim",
                                     @"lastName":@"Example",
                                     @"position":@"CEO",
                                     @"employeeID":@(12)};
        ORMPrimaryKey pk2 = [self.employeeMapping insertEntityWithProperties:properties2
                                                                intoDatabase:db
                                                                       error:&error];
        STAssertTrue(pk2 != 0, [error localizedDescription]);

        
        NSDictionary *properties3 = @{@"firstName":@"Eva",
                                      @"lastName":@"Example",
                                      @"position":@"ETO",
                                      @"employeeID":@(14)};
        ORMPrimaryKey pk3 = [self.employeeMapping insertEntityWithProperties:properties3
                                                                intoDatabase:db
                                                                       error:&error];
        STAssertTrue(pk3 != 0, [error localizedDescription]);
        
        
        return ^(NSError *error) {
            STAssertNil(error, [error localizedDescription]);
            
            NSError *_error = nil;
            
            // Person Properties
            
            NSDictionary *personProperties = [Person propertiesOfORMObjectWithPrimaryKey:pk2
                                                                              inDatabase:db
                                                                                   error:&_error];
            STAssertNotNil(personProperties, [_error localizedDescription]);
            
            NSDictionary *_pp = @{@"firstName":@"Jim", @"lastName":@"Example"};
            STAssertEqualObjects(personProperties, _pp, nil);
            
            // Employee Properties
            
            NSDictionary *employeeProperties = [Employee propertiesOfORMObjectWithPrimaryKey:pk2
                                                                                  inDatabase:db
                                                                                       error:&_error];
            STAssertNotNil(employeeProperties, [_error localizedDescription]);
            
            NSDictionary *_ep = @{@"position":@"CEO", @"fired":[NSNull null], @"employeeID":@(12)};
            STAssertEqualObjects(employeeProperties, _ep, nil);
            
            // All Properties
            
            NSDictionary *allProperties = [Employee propertiesOfORMObjectWithPrimaryKey:pk2
                                                                             inDatabase:db
                                                                                  error:&_error
                                                                 includeSuperProperties:YES];
            STAssertNotNil(allProperties, [_error localizedDescription]);
            
            NSDictionary *_ap = @{@"firstName":@"Jim", @"lastName":@"Example", @"position":@"CEO", @"fired":[NSNull null], @"employeeID":@(12)};
            STAssertEqualObjects(allProperties, _ap, nil);
        };
    }];
}

#pragma mark Test Unique Constraint

- (void)testUniqueConstraint
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        
        // Insert Properties
        
        NSDictionary *properties = @{@"firstName":@"Jim",
                                     @"lastName":@"Example",
                                     @"position":@"CEO",
                                     @"employeeID":@(12)};
        
        ORMPrimaryKey pk = [self.employeeMapping insertEntityWithProperties:properties
                                                               intoDatabase:db
                                                                      error:&error];
        
        STAssertTrue(pk != 0, [error localizedDescription]);
        
        return ^(NSError *error) {
            STAssertNil(error, [error localizedDescription]);
        };
    }];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        
        // Insert Properties
        
        NSDictionary *properties = @{@"firstName":@"John",
                                     @"lastName":@"Example",
                                     @"position":@"CEO",
                                     @"employeeID":@(12)};
        
        ORMPrimaryKey pk = [self.employeeMapping insertEntityWithProperties:properties
                                                               intoDatabase:db
                                                                      error:&error];
        STAssertTrue(pk == 0, nil);
        
        return ^(NSError *error) {
            STAssertNil(error, [error localizedDescription]);
        };
    }];
}

- (void)testUniqueTogetherConstraint
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        
        // Insert Properties
        
        NSDictionary *properties = @{@"firstName":@"Jim",
                                     @"lastName":@"Example"};
        
        ORMPrimaryKey pk = [self.personMapping insertEntityWithProperties:properties
                                                             intoDatabase:db
                                                                    error:&error];
        STAssertTrue(pk != 0, [error localizedDescription]);
        
        return ^(NSError *error) {
            STAssertNil(error, [error localizedDescription]);
        };
    }];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        
        // Insert Properties
        
        NSDictionary *properties = @{@"firstName":@"Jim",
                                     @"lastName":@"Example"};
        
        ORMPrimaryKey pk = [self.personMapping insertEntityWithProperties:properties
                                                             intoDatabase:db
                                                                    error:&error];
        STAssertTrue(pk == 0, nil);
        
        return ^(NSError *error) {
            STAssertNil(error, [error localizedDescription]);
        };
    }];
}

@end
