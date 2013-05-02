//
//  CocoaORMDatabaseSchemataTests.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

// 3rdParty
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseAdditions.h>

#import "CocoaORMDatabaseSchemataTests.h"

@implementation CocoaORMDatabaseSchemataTests

- (void)testSetupSchemata
{
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        BOOL success = [Person setupORMSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        return ^(NSError *error){
            STAssertNil(error, [error localizedDescription]);
            
            STAssertTrue([db tableExists:@"Person"], @"Expecting table 'Person' to exist.");
            STAssertTrue([db columnExists:@"Person" columnName:@"_id"], nil);
            STAssertTrue([db columnExists:@"Person" columnName:@"_class"], nil);
            STAssertTrue([db columnExists:@"Person" columnName:@"firstName"], nil);
            STAssertTrue([db columnExists:@"Person" columnName:@"lastName"], nil);
        };
    }];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        BOOL success = [Employee setupORMSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        return ^(NSError *error){
            STAssertNil(error, [error localizedDescription]);
            
            STAssertTrue([db tableExists:@"Employee"], @"Expecting table 'Employee' to exist.");
            STAssertTrue([db columnExists:@"Employee" columnName:@"_id"], nil);
            STAssertTrue([db columnExists:@"Employee" columnName:@"position"], nil);
            STAssertTrue([db columnExists:@"Employee" columnName:@"fired"], nil);
            
            STAssertFalse([db columnExists:@"Employee" columnName:@"_class"], nil);
        };
    }];
    
    [self.store commitTransactionInDatabaseAndWait:^ORMStoreTransactionCompletionHalndler(FMDatabase *db, BOOL *rollback) {
        
        NSError *error = nil;
        BOOL success = [Chef setupORMSchemataInDatabase:db error:&error];
        STAssertTrue(success, [error localizedDescription]);
        
        return ^(NSError *error){
            STAssertNil(error, [error localizedDescription]);
            
            STAssertTrue([db tableExists:@"Chef"], @"Expecting table 'Chef' to exist.");
            STAssertTrue([db columnExists:@"Employee" columnName:@"_id"], nil);
            STAssertFalse([db columnExists:@"Employee" columnName:@"_class"], nil);
        };
    }];
}

@end
