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
        
        NSDictionary *p = @{@"firstName":@"John", @"lastName":@"Example", @"position":@"CEO", @"fired":[NSNull null]};
        STAssertEqualObjects(allProperties, p, nil);
        
        return nil;
    }];
}

@end
