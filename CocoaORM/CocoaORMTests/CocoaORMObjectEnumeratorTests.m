//
//  CocoaORMObjectEnumeratorTests.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 30.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMObjectEnumeratorTests.h"

@interface CocoaORMObjectEnumeratorTests ()
@property (nonatomic, strong) NSSet *objects;
@end

@implementation CocoaORMObjectEnumeratorTests

- (void)setUp
{
    [super setUp];
    
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        NSMutableSet *objects = [[NSMutableSet alloc] init];
        
        Employee *employee = [[Employee alloc] initWithFirstName:@"John" lastName:@"Example"];
        employee.position = @"CEO";
        employee.employeeID = @(12);
        
        [objects addObject:employee];
        
        [objects addObject:[[Person alloc] initWithFirstName:@"A" lastName:@"a"]];
        [objects addObject:[[Person alloc] initWithFirstName:@"B" lastName:@"b"]];
        [objects addObject:[[Person alloc] initWithFirstName:@"C" lastName:@"c"]];
        [objects addObject:[[Person alloc] initWithFirstName:@"D" lastName:@"d"]];
        [objects addObject:[[Person alloc] initWithFirstName:@"E" lastName:@"e"]];
        [objects addObject:[[Person alloc] initWithFirstName:@"F" lastName:@"f"]];
        
        self.objects = objects;
        
        [objects enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            [self.store insertObject:obj];
        }];
        
        return ^(NSError *error){
            STAssertNil(error, [error localizedDescription]);
        };
    }];
}

#pragma mark Test Enumerator

- (void)testEnumerator
{
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        NSMutableSet *result = [[NSMutableSet alloc] init];
        
        [self.store enumerateObjectsWithClass:[Person class] enumerator:^(id object, BOOL *stop) {
            [result addObject:object];
        }];
        
        STAssertEquals([result count], (NSUInteger)7, nil);
        STAssertEquals(result, self.objects, nil);
        return nil;
    }];
}

@end
