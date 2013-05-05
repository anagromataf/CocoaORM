//
//  ORMClassMapping.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 05.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseAdditions.h>

#import "ORMAttributeDescription.h"
#import "ORMClass.h"

#import "ORMClassMapping.h"

@implementation ORMClassMapping

+ (instancetype)mappingForClass:(Class)mappedClass
{
    static NSMutableDictionary *mappings;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mappings = [[NSMutableDictionary alloc] init];
    });
    
    ORMClassMapping *mapping = [mappings objectForKey:NSStringFromClass(mappedClass)];
    if (!mapping) {
        mapping = [[ORMClassMapping alloc] initWithClass:mappedClass];
        [mappings setObject:mapping forKey:NSStringFromClass(mappedClass)];
    }
    return mapping;
}

#pragma mark Life-cycle

- (id)initWithClass:(Class)mappedClass
{
    self = [super init];
    if (self) {
        _mappedClass = mappedClass;
    }
    return self;
}

#pragma mark Setup Schemata for Entity

- (BOOL)setupSchemataInDatabase:(FMDatabase *)database
                          error:(NSError **)error
{
    BOOL success = YES;
    BOOL baseClass = ![[self.mappedClass superclass] isORMClass];
    
    if (!baseClass) {
        success = [[ORMClassMapping mappingForClass:[self.mappedClass superclass]] setupSchemataInDatabase:database error:error];
    }
    
    if (success) {
        
        if ([database tableExists:self.mappedClass.ORM.entityName]) {
            return YES;
        } else {
            
            NSMutableArray *columns = [[NSMutableArray alloc] init];
            
            if (baseClass) {
                [columns addObject:@"_id INTEGER NOT NULL PRIMARY KEY"];
                [columns addObject:@"_class TEXT NOT NULL"];
            } else {
                [columns addObject:[NSString stringWithFormat:@"_id INTEGER NOT NULL PRIMARY KEY REFERENCES %@(_id) ON DELETE CASCADE", NSStringFromClass([self superclass])]];
            }
            
            NSMutableSet *uniqueConstraints = [self.mappedClass.ORM.uniqueConstraints mutableCopy];
            
            [self.mappedClass.ORM.properties enumerateKeysAndObjectsUsingBlock:^(NSString *name, ORMAttributeDescription *attribute, BOOL *stop) {
                
                NSMutableArray *column = [[NSMutableArray alloc] init];
                
                [column addObject:attribute.attributeName];
                [column addObject:attribute.typeName];
                
                if (attribute.required) {
                    [column addObject:@"NOT NULL"];
                }
                
                if (attribute.uniqueProperty) {
                    [uniqueConstraints addObject:[NSSet setWithObject:name]];
                }
                
                [columns addObject:[column componentsJoinedByString:@" "]];
            }];
            
            [uniqueConstraints enumerateObjectsUsingBlock:^(NSSet *propertyNames, BOOL *stop) {
                [columns addObject:[NSString stringWithFormat:@"UNIQUE (%@)", [[propertyNames allObjects] componentsJoinedByString:@", "]]];
            }];
            
            NSString *statement = [NSString stringWithFormat:@"CREATE TABLE %@ (%@)",
                                   self.mappedClass.ORM.entityName,
                                   [columns componentsJoinedByString:@", "]];
            
            NSLog(@"SQL: %@", statement);
            
            success = [database executeUpdate:statement];
            if (!success && error) {
                *error = database.lastError;
            }
        }
    }
    
    return success;
}

@end
