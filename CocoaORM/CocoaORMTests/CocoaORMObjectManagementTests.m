//
//  CocoaORMObjectManagementTests.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMObjectManagementTests.h"

@implementation CocoaORMObjectManagementTests

- (void)testInsertObject
{
    __block Employee *employee = nil;
    
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        employee = [[Employee alloc] init];
        
        employee.firstName = @"John";
        employee.lastName = @"Example";
        employee.position = @"CEO";
        
        [self.store insertObject:employee];
        
        return ^(NSError *error){
            STAssertNil(error, [error localizedDescription]);
        };
    }];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        STAssertEqualObjects(employee.changedORMValues, @{}, nil);
        
        NSError *error = nil;
        
        NSDictionary *allProperties = [Employee propertiesOfORMObjectWithPrimaryKey:employee.ORMObjectID.primaryKey
                                                                         inDatabase:db
                                                                              error:&error
                                                             includeSuperProperties:YES];
        STAssertNotNil(allProperties, [error localizedDescription]);
        
        NSDictionary *p = @{@"firstName":@"John", @"lastName":@"Example", @"position":@"CEO", @"fired":[NSNull null], @"employeeID":[NSNull null]};
        STAssertEqualObjects(allProperties, p, nil);
        
        return nil;
    }];
}

- (void)testUpdateObject
{
    __block Employee *employee = nil;
    
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        employee = [[Employee alloc] init];
        
        employee.firstName = @"John";
        employee.lastName = @"Example";
        employee.position = @"CEO";
        
        [self.store insertObject:employee];
        
        return ^(NSError *error){
            STAssertNil(error, [error localizedDescription]);
        };
    }];
    
    [self.store commitTransaction:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        employee.fired = @YES;
        return nil;
    }];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        STAssertEqualObjects(employee.changedORMValues, @{}, nil);
        
        NSError *error = nil;
        
        NSDictionary *allProperties = [Employee propertiesOfORMObjectWithPrimaryKey:employee.ORMObjectID.primaryKey
                                                                         inDatabase:db
                                                                              error:&error
                                                             includeSuperProperties:YES];
        STAssertNotNil(allProperties, [error localizedDescription]);
        
        NSDictionary *p = @{@"firstName":@"John", @"lastName":@"Example", @"position":@"CEO", @"fired":@YES, @"employeeID":[NSNull null]};
        STAssertEqualObjects(allProperties, p, nil);
        
        return nil;
    }];
}

- (void)testUpdateObjectAndRollback
{
    __block Employee *employee = nil;
    
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        employee = [[Employee alloc] init];
        
        employee.firstName = @"John";
        employee.lastName = @"Example";
        employee.position = @"CEO";
        
        [self.store insertObject:employee];
        
        return ^(NSError *error){
            STAssertNil(error, [error localizedDescription]);
        };
    }];
    
    [self.store commitTransaction:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        employee.fired = @YES;
        *rollback = YES;
        return nil;
    }];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        STAssertEqualObjects(employee.changedORMValues, @{}, nil);
        
        NSError *error = nil;
        
        NSDictionary *allProperties = [Employee propertiesOfORMObjectWithPrimaryKey:employee.ORMObjectID.primaryKey
                                                                         inDatabase:db
                                                                              error:&error
                                                             includeSuperProperties:YES];
        STAssertNotNil(allProperties, [error localizedDescription]);
        
        NSDictionary *p = @{@"firstName":@"John", @"lastName":@"Example", @"position":@"CEO", @"fired":[NSNull null], @"employeeID":[NSNull null]};
        STAssertEqualObjects(allProperties, p, nil);
        
        return nil;
    }];
}

- (void)testDeleteObject
{
    __block Employee *employee = nil;
    
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        employee = [[Employee alloc] init];
        
        employee.firstName = @"John";
        employee.lastName = @"Example";
        employee.position = @"CEO";
        
        [self.store insertObject:employee];
        
        return ^(NSError *error){
            STAssertNil(error, [error localizedDescription]);
        };
    }];
    
    ORMPrimaryKey pk = employee.ORMObjectID.primaryKey;
    
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        [self.store deleteObject:employee];
        
        return nil;
    }];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        NSDictionary *properties = [Employee propertiesOfORMObjectWithPrimaryKey:pk
                                                                      inDatabase:db                                                                              error:&error];
        STAssertNil(error, [error localizedDescription]);
        STAssertNil(properties, nil);
        
        STAssertNil(employee.ORMObjectID, nil);
        STAssertNil(employee.ORMStore, nil);
        
        STAssertEqualObjects(employee.firstName, @"John", nil);
        STAssertEqualObjects(employee.lastName, @"Example", nil);
        STAssertEqualObjects(employee.position, @"CEO", nil);
        
        return nil;
    }];
}

@end
