//
//  CocoaORMPropertiesTests.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMPropertiesTests.h"

@implementation CocoaORMPropertiesTests

- (void)testInsertProperties
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        
        // Setup Schemata
        
        BOOL success = [Employee setupORMSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        // Insert Properties
        
        NSDictionary *properties = @{@"firstName":@"Jim",
                                      @"lastName":@"Example",
                                      @"position":@"CEO"};
        
        int64_t pk = [Employee insertORMObjectProperties:properties
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
            
            STAssertEquals([result columnCount], 3, nil);
            
            STAssertTrue([result next], nil);
            STAssertEqualObjects([result objectForColumnName:@"_id"], @(pk), nil);
            STAssertEqualObjects([result objectForColumnName:@"position"], @"CEO", nil);
            STAssertEqualObjects([result objectForColumnName:@"fired"], [NSNull null], nil);
            
            STAssertFalse([result next], nil);
        };
    }];
}

@end
