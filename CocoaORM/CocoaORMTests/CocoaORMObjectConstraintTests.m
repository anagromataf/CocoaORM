//
//  CocoaORMObjectConstraintTests.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 29.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMObjectConstraintTests.h"

@interface CocoaORMObjectConstraintTests ()
@property (nonatomic, strong) ORMEntitySQLConnector *personConnector;
@end

@implementation CocoaORMObjectConstraintTests

- (void)setUp
{
    [super setUp];
    
    self.personConnector = [ORMEntitySQLConnector connectorWithEntityDescription:[Person ORMEntityDescription]];
    
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        Employee *employee = [[Employee alloc] init];
        
        employee.firstName = @"John";
        employee.lastName = @"Example";
        employee.position = @"CEO";
        employee.employeeID = @(12);
        
        [self.store insertObject:employee];
        
        return ^(NSError *error){
            STAssertNil(error, [error localizedDescription]);
        };
    }];
}

#pragma mark Constraint Tests

- (void)testConstraint
{
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        Employee *employee = [[Employee alloc] init];
        
        employee.firstName = @"John";
        employee.lastName = @"Example";
        employee.position = @"CEO";
        employee.employeeID = @(12);
        
        [self.store insertObject:employee];
        
        return ^(NSError *error) {
            STAssertNotNil(error, nil);
            
            STAssertNil(employee.ORMObjectID, nil);
            STAssertNil(employee.ORMStore, nil);
        };
    }];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        __block NSUInteger count = 0;
        
        NSError *error = nil;
        BOOL success = [self.personConnector enumerateEntitiesInDatabase:db
                                                                 error:&error
                                                            enumerator:^(ORMPrimaryKey pk, __unsafe_unretained Class klass, BOOL *stop) {
                                                                count++;
                                                            }];
        
        STAssertTrue(success, [error localizedDescription]);
        
        
        STAssertEquals(count, (NSUInteger)1, nil);
        
        return nil;
    }];
}

@end
