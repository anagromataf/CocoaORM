//
//  CocoaORMObjectPropertyLoadingTests.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 30.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMObjectPropertyLoadingTests.h"

@interface CocoaORMObjectPropertyLoadingTests ()

@end

@implementation CocoaORMObjectPropertyLoadingTests

- (void)setUp
{
    [super setUp];
    
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHandler(BOOL *rollback) {
        
        Employee *employee = [self.store createObjectWithEntityDescription:[Employee ORMEntityDescription]];
        
        employee.firstName = @"John";
        employee.lastName = @"Example";
        employee.position = @"CEO";
        employee.employeeID = @(12);
                
        return ^(NSError *error){
            STAssertNil(error, [error localizedDescription]);
        };
    }];
}

#pragma mark Test Property Loading

- (void)testPropertyLoading
{
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHandler(BOOL *rollback) {
        
        [self.store enumerateObjectsWithEntityDescription:[Employee ORMEntityDescription]
                                        matchingCondition:nil
                                            withArguments:nil
                                       fetchingProperties:nil
                                               enumerator:^(Employee *employee, BOOL *stop) {
            STAssertNotNil(employee, nil);
            STAssertEqualObjects(employee.position, @"CEO", nil);
            STAssertEqualObjects(employee.firstName, @"John", nil);
            STAssertEqualObjects(employee.lastName, @"Example", nil);
        }];
        
        return nil;
    }];
}

@end
