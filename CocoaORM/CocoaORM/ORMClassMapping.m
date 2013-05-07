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
                [columns addObject:[NSString stringWithFormat:@"_id INTEGER NOT NULL PRIMARY KEY REFERENCES %@(_id) ON DELETE CASCADE",
                                    [[[self.mappedClass superclass] ORM] entityName]]];
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

#pragma mark Insert, Update & Delete Entity

- (ORMPrimaryKey)insertEntityWithProperties:(NSDictionary *)properties
                               intoDatabase:(FMDatabase *)database
                                      error:(NSError **)error
{
    if ([properties objectForKey:@"_class"] == nil) {
        NSMutableDictionary *_properties = [properties mutableCopy];
        [_properties setObject:NSStringFromClass(self.mappedClass) forKey:@"_class"];
        properties = _properties;
    }
    
    sqlite_int64 pk = 0;
    if ([[self.mappedClass superclass] isORMClass]) {
        pk = [[ORMClassMapping mappingForClass:[self.mappedClass superclass]] insertEntityWithProperties:properties
                                                                                            intoDatabase:database
                                                                                                   error:error];
        if (pk == 0) {
            return 0;
        }
    }
    
    NSMutableArray *columnNames = [[NSMutableArray alloc] init];
    NSMutableArray *columnValues = [[NSMutableArray alloc] init];
    NSMutableDictionary *columnProperties = [[NSMutableDictionary alloc] init];
    if (pk == 0) {
        [columnNames addObject:@"_class"];
        [columnValues addObject:@":_class"];
        [columnProperties setObject:[properties objectForKey:@"_class"]
                             forKey:@"_class"];
    } else {
        [columnNames addObject:@"_id"];
        [columnValues addObject:@":_id"];
        [columnProperties setObject:@(pk)
                             forKey:@"_id"];
    }
    
    [self.mappedClass.ORM.properties enumerateKeysAndObjectsUsingBlock:^(NSString *name,
                                                                         ORMAttributeDescription *attribute,
                                                                         BOOL *stop) {
        id value = [properties objectForKey:name];
        if (value) {
            [columnNames addObject:name];
            [columnValues addObject:[NSString stringWithFormat:@":%@", name]];
            [columnProperties setObject:value forKey:name];
        }
    }];
    
    NSString *statement = [NSString stringWithFormat:@"INSERT INTO %@ (%@) VALUES (%@)",
                           self.mappedClass.ORM.entityName,
                           [columnNames componentsJoinedByString:@", "],
                           [columnValues componentsJoinedByString:@", "]];
    
    NSLog(@"SQL: %@", statement);
    
    if (![database executeUpdate:statement withParameterDictionary:columnProperties]) {
        if (error) {
            *error = database.lastError;
        }
        return 0;
    }
    
    if (pk == 0) {
        pk = database.lastInsertRowId;
    }
    
    return pk;
}

- (BOOL)updateEntityWithPrimaryKey:(ORMPrimaryKey)pk
                    withProperties:(NSDictionary *)properties
                        inDatabase:(FMDatabase *)database
                             error:(NSError **)error
{
    if ([[self.mappedClass superclass] isORMClass]) {
        BOOL success = [[ORMClassMapping mappingForClass:[self.mappedClass superclass]] updateEntityWithPrimaryKey:pk
                                                                                                    withProperties:properties
                                                                                                        inDatabase:database
                                                                                                             error:error];
        if (!success) {
            return NO;
        }
    }
    
    NSMutableArray *columns = [[NSMutableArray alloc] init];
    NSMutableDictionary *columnProperties = [[NSMutableDictionary alloc] init];
    
    [self.mappedClass.ORM.properties enumerateKeysAndObjectsUsingBlock:^(NSString *name,
                                                                         ORMAttributeDescription *attribute,
                                                                         BOOL *stop) {
        id value = [properties objectForKey:name];
        if (value) {
            [columns addObject:[NSString stringWithFormat:@"%@ = :%@", name, name]];
            [columnProperties setObject:value forKey:name];
        }
    }];
    
    if ([columnProperties count] > 0) {
        [columnProperties setObject:@(pk) forKey:@"_id"];
        
        NSString *statement = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE _id == :_id",
                               self.mappedClass.ORM.entityName,
                               [columns componentsJoinedByString:@", "]];
        
        NSLog(@"SQL: %@", statement);
        
        if (![database executeUpdate:statement withParameterDictionary:columnProperties]) {
            if (error) {
                *error = database.lastError;
            }
            return NO;
        }
    }
    
    return YES;

}

- (BOOL)deleteEntityWithPrimaryKey:(ORMPrimaryKey)pk
                        inDatabase:(FMDatabase *)database
                             error:(NSError **)error
{
    if ([[self.mappedClass superclass] isORMClass]) {
        return [[ORMClassMapping mappingForClass:[self.mappedClass superclass]] deleteEntityWithPrimaryKey:pk inDatabase:database error:error];
    }
    
    NSString *statement = [NSString stringWithFormat:@"DELETE FROM %@ WHERE _id = :_id",
                           self.mappedClass.ORM.entityName];
    
    NSLog(@"SQL: %@", statement);
    
    if (![database executeUpdate:statement withParameterDictionary:@{@"_id":@(pk)}]) {
        if (error) {
            *error = database.lastError;
        }
        return NO;
    }
    
    return YES;
}

#pragma mark Check if Entity exists

- (BOOL)existsEntityWithPrimaryKey:(ORMPrimaryKey)pk
                        inDatabase:(FMDatabase *)database
                             error:(NSError **)error
{
    NSString *statement = [NSString stringWithFormat:@"SELECT _id FROM %@ WHERE _id = :_id", self.mappedClass.ORM.entityName];
    NSLog(@"SQL: %@", statement);
    
    FMResultSet *result = [database executeQuery:statement withParameterDictionary:@{@"_id":@(pk)}];
    if (result) {
        if ([result next]) {
            return YES;
        } else {
            return NO;
        }
    } else {
        if (error) {
            *error = database.lastError;
        }
        return NO;
    }
}

#pragma mark Get Properties of Entity

- (NSDictionary *)propertiesOfEntityWithPrimaryKey:(ORMPrimaryKey)pk
                                        inDatabase:(FMDatabase *)database
                                             error:(NSError **)error
{
    return [self propertiesOfEntityWithPrimaryKey:pk inDatabase:database error:error includeSuperProperties:NO];
}

- (NSDictionary *)propertiesOfEntityWithPrimaryKey:(ORMPrimaryKey)pk
                                        inDatabase:(FMDatabase *)database
                                             error:(NSError **)error
                            includeSuperProperties:(BOOL)includeSuperProperties
{
    NSString *statement = nil;
    if (includeSuperProperties) {
        NSArray *classes = [[self.mappedClass.ORM.entityHierarchy reverseObjectEnumerator] allObjects];
        statement = [NSString stringWithFormat:@"SELECT * FROM %@",
                     [classes componentsJoinedByString:@" NATURAL JOIN "]];
    } else {
        statement = [NSString stringWithFormat:@"SELECT * FROM %@", self.mappedClass.ORM.entityName];
    }
    statement = [statement stringByAppendingString:@" WHERE _id = :_id"];
    
    NSLog(@"SQL: %@", statement);
    
    FMResultSet *result = [database executeQuery:statement withParameterDictionary:@{@"_id":@(pk)}];
    if (result) {
        if ([result next]) {
            NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
            
            NSDictionary *propertyDesctiptions = nil;
            if (includeSuperProperties) {
                propertyDesctiptions = self.mappedClass.ORM.allProperties;
            } else {
                propertyDesctiptions = self.mappedClass.ORM.properties;
            }
            
            [propertyDesctiptions enumerateKeysAndObjectsUsingBlock:^(NSString *name, ORMAttributeDescription *attribute, BOOL *stop) {
                id value = [result objectForColumnName:name];
                [properties setObject:value forKey:name];
            }];
            return properties;
        } else {
            return nil;
        }
    } else {
        if (error) {
            *error = database.lastError;
        }
        return nil;
    }
}

@end
