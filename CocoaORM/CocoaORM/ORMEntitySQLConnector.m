//
//  ORMEntitySQLConnector.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 05.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseAdditions.h>

#import "ORMAttributeDescription.h"
#import "ORMEntityDescription.h"

#import "ORMEntitySQLConnector.h"

@interface ORMEntitySQLConnector ()
@property (nonatomic, readonly) ORMEntitySQLConnector *superConnector;
@end

@implementation ORMEntitySQLConnector

+ (instancetype)connectorWithEntityDescription:(ORMEntityDescription *)entityDescription
{
    return [[ORMEntitySQLConnector alloc] initWithEntityDescription:entityDescription];
}

#pragma mark Life-cycle

- (id)initWithEntityDescription:(ORMEntityDescription *)entityDescription;
{
    self = [super init];
    if (self) {
        _entityDescription = entityDescription;
    }
    return self;
}

#pragma mark Super Connector

- (ORMEntitySQLConnector *)superConnector
{
    if (self.entityDescription.superentity) {
        return [ORMEntitySQLConnector connectorWithEntityDescription:self.entityDescription.superentity];
    } else {
        return nil;
    }
}

#pragma mark Setup Schemata for Entity

- (BOOL)setupSchemataInDatabase:(FMDatabase *)database
                          error:(NSError **)error
{
    BOOL success = YES;
    
    if (self.superConnector) {
        success = [self.superConnector setupSchemataInDatabase:database error:error];
    }
    
    if (success) {
        
        if ([database tableExists:self.entityDescription.name]) {
            return YES;
        } else {
            
            NSMutableArray *columns = [[NSMutableArray alloc] init];
            
            if (self.superConnector) {
                [columns addObject:[NSString stringWithFormat:@"_id INTEGER NOT NULL PRIMARY KEY REFERENCES %@(_id) ON DELETE CASCADE",
                                    self.superConnector.entityDescription.name]];
            } else {
                [columns addObject:@"_id INTEGER NOT NULL PRIMARY KEY"];
                [columns addObject:@"_class TEXT NOT NULL"];
            }
            
            NSMutableSet *uniqueConstraints = [self.entityDescription.uniqueConstraints mutableCopy];
            
            [self.entityDescription.properties enumerateKeysAndObjectsUsingBlock:^(NSString *name, ORMAttributeDescription *attribute, BOOL *stop) {
                
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
                                   self.entityDescription.name,
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

- (ORMEntityID)insertEntityWithProperties:(NSDictionary *)properties
                               intoDatabase:(FMDatabase *)database
                                      error:(NSError **)error
{
    if ([properties objectForKey:@"_class"] == nil) {
        NSMutableDictionary *_properties = [properties mutableCopy];
        [_properties setObject:NSStringFromClass(self.entityDescription.managedClass) forKey:@"_class"];
        properties = _properties;
    }
    
    sqlite_int64 eid = 0;
    if (self.superConnector) {
        eid = [self.superConnector insertEntityWithProperties:properties
                                                intoDatabase:database
                                                       error:error];
        if (eid == 0) {
            return 0;
        }
    }
    
    NSMutableArray *columnNames = [[NSMutableArray alloc] init];
    NSMutableArray *columnValues = [[NSMutableArray alloc] init];
    NSMutableDictionary *columnProperties = [[NSMutableDictionary alloc] init];
    if (eid == 0) {
        [columnNames addObject:@"_class"];
        [columnValues addObject:@":_class"];
        [columnProperties setObject:[properties objectForKey:@"_class"]
                             forKey:@"_class"];
    } else {
        [columnNames addObject:@"_id"];
        [columnValues addObject:@":_id"];
        [columnProperties setObject:@(eid)
                             forKey:@"_id"];
    }
    
    [self.entityDescription.properties enumerateKeysAndObjectsUsingBlock:^(NSString *name,
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
                           self.entityDescription.name,
                           [columnNames componentsJoinedByString:@", "],
                           [columnValues componentsJoinedByString:@", "]];
    
    NSLog(@"SQL: %@", statement);
    
    if (![database executeUpdate:statement withParameterDictionary:columnProperties]) {
        if (error) {
            *error = database.lastError;
        }
        return 0;
    }
    
    if (eid == 0) {
        eid = database.lastInsertRowId;
    }
    
    return eid;
}

- (BOOL)updateEntityWithEntityID:(ORMEntityID)eid
                    withProperties:(NSDictionary *)properties
                        inDatabase:(FMDatabase *)database
                             error:(NSError **)error
{
    if (self.superConnector) {
        BOOL success = [self.superConnector updateEntityWithEntityID:eid
                                                        withProperties:properties
                                                            inDatabase:database
                                                                 error:error];
        if (!success) {
            return NO;
        }
    }
    
    NSMutableArray *columns = [[NSMutableArray alloc] init];
    NSMutableDictionary *columnProperties = [[NSMutableDictionary alloc] init];
    
    [self.entityDescription.properties enumerateKeysAndObjectsUsingBlock:^(NSString *name,
                                                                           ORMAttributeDescription *attribute,
                                                                           BOOL *stop) {
        id value = [properties objectForKey:name];
        if (value) {
            [columns addObject:[NSString stringWithFormat:@"%@ = :%@", name, name]];
            [columnProperties setObject:value forKey:name];
        }
    }];
    
    if ([columnProperties count] > 0) {
        [columnProperties setObject:@(eid) forKey:@"_id"];
        
        NSString *statement = [NSString stringWithFormat:@"UPDATE %@ SET %@ WHERE _id == :_id",
                               self.entityDescription.name,
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

- (BOOL)deleteEntityWithEntityID:(ORMEntityID)eid
                        inDatabase:(FMDatabase *)database
                             error:(NSError **)error
{
    if (self.superConnector) {
        return [self.superConnector deleteEntityWithEntityID:eid inDatabase:database error:error];
    }
    
    NSString *statement = [NSString stringWithFormat:@"DELETE FROM %@ WHERE _id = :_id",
                           self.entityDescription.name];
    
    NSLog(@"SQL: %@", statement);
    
    if (![database executeUpdate:statement withParameterDictionary:@{@"_id":@(eid)}]) {
        if (error) {
            *error = database.lastError;
        }
        return NO;
    }
    
    return YES;
}

#pragma mark Check if Entity exists

- (BOOL)existsEntityWithEntityID:(ORMEntityID)eid
                        inDatabase:(FMDatabase *)database
                             error:(NSError **)error
{
    NSString *statement = [NSString stringWithFormat:@"SELECT _id FROM %@ WHERE _id = :_id", self.entityDescription.name];
    NSLog(@"SQL: %@", statement);
    
    FMResultSet *result = [database executeQuery:statement withParameterDictionary:@{@"_id":@(eid)}];
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

- (NSDictionary *)propertiesOfEntityWithEntityID:(ORMEntityID)eid
                                        inDatabase:(FMDatabase *)database
                                             error:(NSError **)error
{
    return [self propertiesOfEntityWithEntityID:eid inDatabase:database error:error includeSuperProperties:NO];
}

- (NSDictionary *)propertiesOfEntityWithEntityID:(ORMEntityID)eid
                                        inDatabase:(FMDatabase *)database
                                             error:(NSError **)error
                            includeSuperProperties:(BOOL)includeSuperProperties
{
    NSString *statement = nil;
    if (includeSuperProperties) {
        NSArray *classes = [[self.entityDescription.entityHierarchy reverseObjectEnumerator] allObjects];
        statement = [NSString stringWithFormat:@"SELECT * FROM %@",
                     [classes componentsJoinedByString:@" NATURAL JOIN "]];
    } else {
        statement = [NSString stringWithFormat:@"SELECT * FROM %@", self.entityDescription.name];
    }
    statement = [statement stringByAppendingString:@" WHERE _id = :_id"];
    
    NSLog(@"SQL: %@", statement);
    
    FMResultSet *result = [database executeQuery:statement withParameterDictionary:@{@"_id":@(eid)}];
    if (result) {
        if ([result next]) {
            NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
            
            NSDictionary *propertyDesctiptions = nil;
            if (includeSuperProperties) {
                propertyDesctiptions = self.entityDescription.allProperties;
            } else {
                propertyDesctiptions = self.entityDescription.properties;
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

#pragma mark Enumerate Entities

- (BOOL)enumerateEntitiesInDatabase:(FMDatabase *)database
                              error:(NSError **)error
                         enumerator:(void(^)(ORMEntityID eid, Class klass, BOOL *stop))enumerator
{
    return [self enumerateEntitiesInDatabase:database
                           matchingCondition:nil
                               withArguments:nil
                          fetchingProperties:nil
                                       error:error
                                  enumerator:^(ORMEntityID eid, __unsafe_unretained Class klass, NSDictionary *properties, BOOL *stop) {
                                      enumerator(eid, klass, stop);
                                  }];
}

- (BOOL)enumerateEntitiesInDatabase:(FMDatabase *)database
                 fetchingProperties:(NSArray *)propertyNames
                              error:(NSError **)error
                         enumerator:(void(^)(ORMEntityID eid, Class klass, NSDictionary *properties, BOOL *stop))enumerator
{
    return [self enumerateEntitiesInDatabase:database
                           matchingCondition:nil
                               withArguments:nil
                          fetchingProperties:propertyNames
                                       error:error
                                  enumerator:enumerator];
}

- (BOOL)enumerateEntitiesInDatabase:(FMDatabase *)database
                  matchingCondition:(NSString *)condition
                      withArguments:(NSDictionary *)arguments
                 fetchingProperties:(NSArray *)propertyNames
                              error:(NSError **)error
                         enumerator:(void (^)(ORMEntityID eid, Class klass, NSDictionary *properties, BOOL *stop))enumerator
{
    if (propertyNames == nil) {
        propertyNames = @[];
    }
    
    NSArray *classes = [[self.entityDescription.entityHierarchy reverseObjectEnumerator] allObjects];
    
    NSString *statement = [NSString stringWithFormat:@"SELECT %@ FROM %@",
                           [[propertyNames arrayByAddingObjectsFromArray:@[@"_id", @"_class"]] componentsJoinedByString:@", "],
                           [classes componentsJoinedByString:@" NATURAL JOIN "]];
    
    if (condition) {
        statement = [statement stringByAppendingFormat:@" WHERE %@", condition];
    }
    
    NSLog(@"SQL: %@", statement);
    
    FMResultSet *result = [database executeQuery:statement withParameterDictionary:arguments];
    if (result) {
        
        BOOL stop = NO;
        while (stop == NO && [result next]) {
            ORMEntityID eid = [[result objectForColumnName:@"_id"] integerValue];
            Class klass = NSClassFromString([result objectForColumnName:@"_class"]);
            
            NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
            [propertyNames enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
                id value = [result objectForColumnName:name];
                [properties setObject:value forKey:name];
            }];
            enumerator(eid, klass, properties, &stop);
        }
        
        return YES;
    } else {
        if (error) {
            *error = database.lastError;
        }
        return NO;
    }
}

@end
