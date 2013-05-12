//
//  CocoaORMObjectEnumeratorTests.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 30.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMObjectEnumeratorTests.h"

@interface Person (ORM)
+ (instancetype)createWithFirstName:(NSString *)firstName lastName:(NSString *)lastName inStore:(ORMStore *)store;
@end

@implementation Person (ORM)
+ (instancetype)createWithFirstName:(NSString *)firstName lastName:(NSString *)lastName inStore:(ORMStore *)store
{
    Person *person = [store createObjectWithEntityDescription:[self ORMEntityDescription]];
    person.firstName = firstName;
    person.lastName = lastName;
    return person;
}
@end

@interface CocoaORMObjectEnumeratorTests ()
@property (nonatomic, strong) NSSet *objects;
@end

@implementation CocoaORMObjectEnumeratorTests

- (void)setUp
{
    [super setUp];
    
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        NSMutableSet *objects = [[NSMutableSet alloc] init];
        
        Employee *employee = [Employee createWithFirstName:@"John" lastName:@"Example" inStore:self.store];
        employee.position = @"CEO";
        employee.employeeID = @(12);
        
        [objects addObject:employee];
        
        [objects addObject:[Person createWithFirstName:@"A" lastName:@"a" inStore:self.store]];
        [objects addObject:[Person createWithFirstName:@"B" lastName:@"b" inStore:self.store]];
        [objects addObject:[Person createWithFirstName:@"C" lastName:@"c" inStore:self.store]];
        [objects addObject:[Person createWithFirstName:@"D" lastName:@"d" inStore:self.store]];
        [objects addObject:[Person createWithFirstName:@"E" lastName:@"e" inStore:self.store]];
        [objects addObject:[Person createWithFirstName:@"F" lastName:@"f" inStore:self.store]];
        
        self.objects = objects;
        
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
        
        [self.store enumerateObjectsOfClass:[Person class] enumerator:^(id object, BOOL *stop) {
            [result addObject:object];
        }];
        
        STAssertEquals([result count], (NSUInteger)7, nil);
        STAssertEqualObjects(result, self.objects, nil);
        return nil;
    }];
}

- (void)testEnumeratorWithCondition
{
    [self.store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        NSArray *lastNames = @[@"a", @"b", @"f"];
        
        NSMutableSet *result = [[NSMutableSet alloc] init];
        
        [self.store enumerateObjectsOfClass:[Person class]
                          matchingCondition:@"lastName IN ('a', 'b', 'f')"
                              withArguments:nil
                         fetchingProperties:nil
                                 enumerator:^(id object, BOOL *stop) {
            [result addObject:object];
        }];
        
        STAssertEquals([result count], (NSUInteger)3, nil);
        STAssertEqualObjects(result, [self.objects filteredSetUsingPredicate:
                                      [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return [lastNames containsObject:[evaluatedObject lastName]];
        }]], nil);
        return nil;
    }];
}

@end
