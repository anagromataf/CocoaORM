//
//  CocoaORMDatabaseRollbackTests.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMDatabaseRollbackTests.h"

@interface CocoaORMDatabaseRollbackTests ()
@property (nonatomic, assign) ORMPrimaryKey employeePK;
@end

@implementation CocoaORMDatabaseRollbackTests

- (void)setUp
{
    [super setUp];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        BOOL success = YES;
        
        // Setup Schemata
        
        success = [self.employeeConnector setupSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        // Insert Properties
        
        NSDictionary *properties1 = @{@"firstName":@"Jim",
                                      @"lastName":@"Example",
                                      @"position":@"CEO"};
        
        self.employeePK = [self.employeeConnector insertEntityWithProperties:properties1
                                                              intoDatabase:db
                                                                     error:&error];
        STAssertTrue(self.employeePK != 0, [error localizedDescription]);
        
        return ^(NSError *error) {
            STAssertNil(error, [error localizedDescription]);
        };
    }];
}

#pragma mark Test Rollback

- (void)testRollbackUpdate
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        BOOL success = YES;
        
        // Update Properties
        success = [self.employeeConnector updateEntityWithPrimaryKey:self.employeePK
                                                    withProperties:@{@"firstName":@"John", @"position":@"CTO"}
                                                        inDatabase:db
                                                             error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        FMResultSet *result = nil;
        
        result = [db executeQuery:@"SELECT * FROM Person NATURAL JOIN Employee WHERE _id = :_id"
          withParameterDictionary:@{@"_id":@(self.employeePK)}];
        STAssertNotNil(result, [db.lastError localizedDescription]);
        
        STAssertTrue([result next], nil);
        STAssertEqualObjects([result objectForColumnName:@"position"], @"CTO", nil);
        
        *rollback = YES;
        
        return ^(NSError *error) {
            STAssertNil(error, [error localizedDescription]);
            
            FMResultSet *result = nil;
            
            result = [db executeQuery:@"SELECT * FROM Person NATURAL JOIN Employee WHERE _id = :_id"
              withParameterDictionary:@{@"_id":@(self.employeePK)}];
            STAssertNotNil(result, [db.lastError localizedDescription]);
            
            STAssertTrue([result next], nil);
            STAssertEqualObjects([result objectForColumnName:@"position"], @"CEO", nil);
        };
    }];
}

@end
