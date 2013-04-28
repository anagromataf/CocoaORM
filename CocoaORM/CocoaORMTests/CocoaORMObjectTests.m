//
//  CocoaORMObjectTests.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMObjectTests.h"

@implementation CocoaORMObjectTests

- (void)testPropertySetterAndGetter
{
    Employee *employee = [[Employee alloc] init];

    employee.firstName = @"John";
    employee.lastName = @"Example";
    employee.position = @"CEO";
    
    STAssertEqualObjects(employee.firstName, @"John", nil);
    STAssertEqualObjects(employee.lastName, @"Example", nil);
    STAssertEqualObjects(employee.position, @"CEO", nil);
    
    employee.position = nil;
    STAssertNil(employee.position, nil);
    
    NSDictionary *changedValues = @{@"firstName":@"John", @"lastName":@"Example"};
    STAssertEqualObjects(employee.changedORMValues, changedValues, nil);
}

@end
