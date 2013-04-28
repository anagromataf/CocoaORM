//
//  NSObject+CocoaORM.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

// Cocoa
#import <objc/runtime.h>

// 3rdParty
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseAdditions.h>

#import "NSObject+CocoaORM.h"

const char * NSObjectORMPropertyDescriptionsKey = "NSObjectORMPropertyDescriptionsKey";


@implementation NSObject (CocoaORM)

#pragma mark ORM Descriptions

+ (BOOL)isORMClass
{
    if (self == [NSObject class]) {
        return NO;
    } else if (objc_getAssociatedObject(self, NSObjectORMPropertyDescriptionsKey) != nil) {
        return YES;
    } else {
        return [[self superclass] isORMClass];
    }
}

+ (NSArray *)ORMClassHierarchy
{
    if ([[self superclass] isORMClass]) {
        return [[[self superclass] ORMClassHierarchy] arrayByAddingObject:[self class]];
    } else if ([self isORMClass]) {
        return @[[self class]];
    } else {
        return nil;
    }
}

+ (NSDictionary *)ORMProperties
{
    return [[self ORMPropertyDescriptions] copy];
}

+ (NSDictionary *)allORMProperties
{
    if ([[self superclass] isORMClass]) {
        NSMutableDictionary *properties = [[[self superclass] allORMProperties] mutableCopy];
        [properties addEntriesFromDictionary:[self ORMProperties]];
        return properties;
    } else {
        return [self ORMProperties];
    }
}

#pragma mark ORM Property Descriptions

+ (NSMutableDictionary *)ORMPropertyDescriptions
{
    NSMutableDictionary *propertyDescriptions = objc_getAssociatedObject(self, NSObjectORMPropertyDescriptionsKey);
    if (!propertyDescriptions) {
        propertyDescriptions = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self,
                                 NSObjectORMPropertyDescriptionsKey,
                                 propertyDescriptions,
                                 OBJC_ASSOCIATION_RETAIN);
    }
    return propertyDescriptions;
}

#pragma mark ORM Values

- (id)ORMValueForKey:(NSString *)key;
{
    return nil;
}

- (void)setORMValue:(id)value forKey:(NSString *)key;
{
}

#pragma mark Setup ORM Schema

+ (BOOL)setupORMSchemataInDatabase:(FMDatabase *)database
                             error:(NSError **)error
{
    BOOL success = YES;
    BOOL baseClass = ![[self superclass] isORMClass];
    
    if (!baseClass) {
        success = [[self superclass] setupORMSchemataInDatabase:database
                                                          error:error];
    }
    
    if (success) {
        
        if ([database tableExists:NSStringFromClass(self)]) {
            return YES;
        } else {
            
            NSMutableArray *columns = [[NSMutableArray alloc] init];
            
            if (baseClass) {
                [columns addObject:@"_id INTEGER NOT NULL PRIMARY KEY"];
                [columns addObject:@"_class TEXT NOT NULL"];
            } else {
                [columns addObject:[NSString stringWithFormat:@"_id INTEGER NOT NULL PRIMARY KEY REFERENCES %@(_id) ON DELETE CASCADE", NSStringFromClass([self superclass])]];
            }
            
            [[self ORMProperties] enumerateKeysAndObjectsUsingBlock:^(NSString *name, ORMAttributeDescription *attribute, BOOL *stop) {
                
                NSMutableArray *column = [[NSMutableArray alloc] init];
                
                [column addObject:attribute.attributeName];
                [column addObject:attribute.typeName];
                
                if (attribute.required) {
                    [column addObject:@"NOT NULL"];
                }
                
                [columns addObject:[column componentsJoinedByString:@" "]];
            }];
            
            NSString *statement = [NSString stringWithFormat:@"CREATE TABLE %@ (%@)",
                                   NSStringFromClass(self),
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

#pragma mark Insert and Update Properties

+ (int64_t)insertORMObjectProperties:(NSDictionary *)properties
                        intoDatabase:(FMDatabase *)database
                               error:(NSError **)error
{
    if ([properties objectForKey:@"_class"] == nil) {
        NSMutableDictionary *_properties = [properties mutableCopy];
        [_properties setObject:[self class] forKey:@"_class"];
        properties = _properties;
    }
    
    sqlite_int64 pk = 0;
    if ([[self superclass] isORMClass]) {
        pk = [[self superclass] insertORMObjectProperties:properties
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
    
    [[[self class] ORMProperties] enumerateKeysAndObjectsUsingBlock:^(NSString *name,
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
                           NSStringFromClass([self class]),
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


+ (BOOL)updateORMObjectWithPrimaryKey:(int64_t)pk
                       withProperties:(NSDictionary *)properties
                           inDatabase:(FMDatabase *)database
                                error:(NSError **)error
{
    if ([[self superclass] isORMClass]) {
        BOOL success = [[self superclass] updateORMObjectWithPrimaryKey:pk
                                                         withProperties:properties
                                                             inDatabase:database
                                                                  error:error];
        if (!success) {
            return NO;
        }
    }
    
    NSMutableArray *columns = [[NSMutableArray alloc] init];
    NSMutableDictionary *columnProperties = [[NSMutableDictionary alloc] init];
    
    [[[self class] ORMProperties] enumerateKeysAndObjectsUsingBlock:^(NSString *name,
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
                               NSStringFromClass([self class]),
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

+ (BOOL)deleteORMObjectWithPrimaryKey:(int64_t)pk
                           inDatabase:(FMDatabase *)database
                                error:(NSError **)error
{
    if ([[self superclass] isORMClass]) {
        return [[self superclass] deleteORMObjectWithPrimaryKey:pk inDatabase:database error:error];
    }
    
    NSString *statement = [NSString stringWithFormat:@"DELETE FROM %@ WHERE _id = :_id",
                           NSStringFromClass(self)];
    
    NSLog(@"SQL: %@", statement);
    
    if (![database executeUpdate:statement withParameterDictionary:@{@"_id":@(pk)}]) {
        if (error) {
            *error = database.lastError;
        }
        return NO;
    }
    
    return YES;
}

#pragma mark Get Properties

+ (NSDictionary *)propertiesOfORMObjectWithPrimaryKey:(int64_t)pk
                                           inDatabase:(FMDatabase *)database
                                                error:(NSError **)error
{
    return [self propertiesOfORMObjectWithPrimaryKey:pk inDatabase:database error:error includeSuperProperties:NO];
}

+ (NSDictionary *)propertiesOfORMObjectWithPrimaryKey:(int64_t)pk
                                           inDatabase:(FMDatabase *)database
                                                error:(NSError **)error
                               includeSuperProperties:(BOOL)includeSuperProperties
{
    NSString *statement = nil;
    if (includeSuperProperties) {
        NSArray *classes = [[[self ORMClassHierarchy] reverseObjectEnumerator] allObjects];
        statement = [NSString stringWithFormat:@"SELECT * FROM %@",
                     [classes componentsJoinedByString:@" NATURAL JOIN "]];
    } else {
        statement = [NSString stringWithFormat:@"SELECT * FROM %@", NSStringFromClass(self)];
    }
    
    NSLog(@"SQL: %@", statement);
    
    FMResultSet *result = [database executeQuery:statement];
    if (result) {
        if ([result next]) {
            NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
            
            NSDictionary *propertyDesctiptions = nil;
            if (includeSuperProperties) {
                propertyDesctiptions = [self allORMProperties];
            } else {
                propertyDesctiptions = [self ORMProperties];
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

#pragma mark -

ORMAttributeDescription *
ORMAttribute(Class _class, NSString *name)
{
    ORMAttributeDescription *attribute = [[ORMAttributeDescription alloc] initWithName:name];
    
    [[_class ORMPropertyDescriptions] setObject:attribute forKey:name];
    
    // Add Getter
    class_addMethod(_class,
                    NSSelectorFromString(name),
                    imp_implementationWithBlock((id)^(id obj){
        return [obj ORMValueForKey:name];
    }), "@@:");
    
    // Add Setter
    
    NSString *setterSelectorName = [NSString stringWithFormat:@"set%@:",
                                    [name stringByReplacingCharactersInRange:NSMakeRange(0,1)
                                                                  withString:[[name substringToIndex:1] capitalizedString]]];
    class_addMethod(_class,
                    NSSelectorFromString(setterSelectorName),
                    imp_implementationWithBlock(^(id obj, id value){
        [obj setORMValue:value forKey:name];
    }), "v@:@");
    
    return attribute;
}
