//
//  CocoaORMDatabaseEnumerateTests.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMDatabaseEnumerateTests.h"

@interface CocoaORMDatabaseEnumerateTests ()
@property (nonatomic, assign) ORMPrimaryKey employeePK;
@property (nonatomic, assign) ORMPrimaryKey personPK;
@end

@implementation CocoaORMDatabaseEnumerateTests

- (void)setUp
{
    [super setUp];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        BOOL success = YES;
        
        success = [self.personMapping setupSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        success = [self.employeeMapping setupSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        success = [self.chefMapping setupSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        // Insert Properties
        
        NSDictionary *properties1 = @{@"firstName":@"Jim",
                                      @"lastName":@"Example",
                                      @"position":@"CEO"};
        
        self.employeePK = [self.employeeMapping insertEntityWithProperties:properties1
                                                              intoDatabase:db
                                                                     error:&error];
        STAssertTrue(self.employeePK != 0, [error localizedDescription]);
        
        
        NSDictionary *properties2 = @{@"firstName":@"John",
                                      @"lastName":@"Example"};
        self.personPK = [self.personMapping insertEntityWithProperties:properties2
                                                          intoDatabase:db
                                                                 error:&error];
        STAssertTrue(self.personPK, [error localizedDescription]);
        
        return ^(NSError *error) {
            STAssertNil(error, [error localizedDescription]);
        };
    }];
}

#pragma mark Test Enumerator

- (void)testEnumerate
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSMutableSet *primaryKeys = [[NSMutableSet alloc] init];
        NSMutableSet *classes = [[NSMutableSet alloc] init];
        
        NSError *error = nil;
        BOOL success = [Person enumerateORMObjectsInDatabase:db
                                                       error:&error
                                                  enumerator:^(ORMPrimaryKey pk, __unsafe_unretained Class klass, BOOL *stop) {
                                                      [primaryKeys addObject:@(pk)];
                                                      [classes addObject:klass];
                                                  }];
        STAssertTrue(success, [error localizedDescription]);
        
        NSSet *_p = [NSSet setWithObjects:@(self.employeePK), @(self.personPK), nil];
        STAssertEqualObjects(primaryKeys, _p, nil);
        
        NSSet *_c = [NSSet setWithObjects:[Employee class], [Person class], nil];
        STAssertEqualObjects(classes, _c, nil);
        
        return nil;
    }];
}

- (void)testEnumerateAndStop
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSMutableSet *primaryKeys = [[NSMutableSet alloc] init];

        NSError *error = nil;
        BOOL success = [Person enumerateORMObjectsInDatabase:db
                                                       error:&error
                                                  enumerator:^(ORMPrimaryKey pk, __unsafe_unretained Class klass, BOOL *stop) {
                                                      [primaryKeys addObject:@(pk)];
                                                      *stop = YES;
                                                  }];
        STAssertTrue(success, [error localizedDescription]);
        STAssertEquals([primaryKeys count], (NSUInteger)1, nil);
        return nil;
    }];
}


- (void)testEnumerateWithProperties
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSMutableSet *primaryKeys = [[NSMutableSet alloc] init];
        NSMutableSet *classes = [[NSMutableSet alloc] init];
        
        NSError *error = nil;
        BOOL success = [Person enumerateORMObjectsInDatabase:db
                                          fetchingProperties:@[@"lastName"]
                                                       error:&error
                                                  enumerator:^(ORMPrimaryKey pk, __unsafe_unretained Class klass, NSDictionary *properties, BOOL *stop) {
                                                      [primaryKeys addObject:@(pk)];
                                                      [classes addObject:klass];
                                                      STAssertEqualObjects(properties, @{@"lastName":@"Example"}, nil);
                                                  }];
        STAssertTrue(success, [error localizedDescription]);
        
        NSSet *_p = [NSSet setWithObjects:@(self.employeePK), @(self.personPK), nil];
        STAssertEqualObjects(primaryKeys, _p, nil);
        
        NSSet *_c = [NSSet setWithObjects:[Employee class], [Person class], nil];
        STAssertEqualObjects(classes, _c, nil);
        
        return nil;
    }];
}

- (void)testEnumerateWithCondition
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        NSError *error = nil;
        ORMPrimaryKey pk = [self.personMapping insertEntityWithProperties:@{@"firstName":@"John",  @"lastName":@"Tester"}
                                                             intoDatabase:db
                                                                    error:&error];
        STAssertTrue(pk != 0, [error localizedDescription]);
        return nil;
    }];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        BOOL success = [Person enumerateORMObjectsInDatabase:db
                                           matchingCondition:@"lastName = :lastName"
                                               withArguments:@{@"lastName":@"Example"}
                                          fetchingProperties:@[@"lastName"]
                                                       error:&error
                                                  enumerator:^(ORMPrimaryKey pk, __unsafe_unretained Class klass, NSDictionary *properties, BOOL *stop) {
                                                      STAssertEqualObjects(properties, @{@"lastName":@"Example"}, nil);
                                                  }];
        STAssertTrue(success, [error localizedDescription]);
        
        return nil;
    }];
}

@end
