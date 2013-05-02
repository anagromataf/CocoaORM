//
//  CocoaORMObjectPropertyLoadingTests.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 30.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMObjectPropertyLoadingTests.h"

@interface CocoaORMObjectPropertyLoadingTests ()
@property (nonatomic, strong) ORMObjectID *objectID;
@end

@implementation CocoaORMObjectPropertyLoadingTests

- (void)setUp
{
    [super setUp];
    
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        Employee *employee = [[Employee alloc] init];
        
        employee.firstName = @"John";
        employee.lastName = @"Example";
        employee.position = @"CEO";
        employee.employeeID = @(12);
        
        [self.store insertObject:employee];
        
        return ^(NSError *error){
            STAssertNil(error, [error localizedDescription]);
            self.objectID = employee.ORMObjectID;
        };
    }];
}

#pragma mark Test Property Loading

- (void)testPropertyLoading
{
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        Employee *employee = [self.store objectWithID:self.objectID];
        STAssertNotNil(employee, nil);
        STAssertEqualObjects(employee.ORMObjectID, self.objectID, nil);
        
        STAssertEqualObjects([employee performSelector:@selector(persistentORMValues)], @{}, nil);
        
        STAssertEqualObjects(employee.position, @"CEO", nil);
        
        NSDictionary *_ep = @{@"position":@"CEO", @"fired":[NSNull null], @"employeeID":@(12)};
        STAssertEqualObjects([employee performSelector:@selector(persistentORMValues)], _ep, nil);
        
        STAssertEqualObjects(employee.firstName, @"John", nil);
        STAssertEqualObjects(employee.lastName, @"Example", nil);
        
        NSDictionary *_ap = @{@"firstName":@"John", @"lastName":@"Example", @"position":@"CEO", @"fired":[NSNull null], @"employeeID":@(12)};
        STAssertEqualObjects([employee performSelector:@selector(persistentORMValues)], _ap, nil);
        
        return nil;
    }];
}

@end
