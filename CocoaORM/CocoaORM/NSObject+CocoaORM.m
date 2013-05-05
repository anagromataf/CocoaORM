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

// CocoaORM
#import "ORMClass.h"
#import "ORMStore+Private.h"

#import "NSObject+CocoaORM.h"
#import "NSObject+CocoaORMPrivate.h"

NSString * const NSObjectORMValuesDidChangeNotification = @"NSObjectORMValuesDidChangeNotification";

const char * NSObjectORMPropertyDescriptionsKey         = "NSObjectORMPropertyDescriptionsKey";
const char * NSObjectORMUniqueTogetherPropertyNamesKey  = "NSObjectORMUniqueTogetherPropertyNamesKey";
const char * NSObjectORMObjectIDKey                     = "NSObjectORMObjectIDKey";
const char * NSObjectORMStoreKey                        = "NSObjectORMStoreKey";

@implementation NSObject (CocoaORM)

#pragma mark ORM Object ID & Store

- (ORMObjectID *)ORMObjectID
{
    return objc_getAssociatedObject(self, NSObjectORMObjectIDKey);
}

- (void)setORMObjectID:(ORMObjectID *)ORMObjectID
{
    objc_setAssociatedObject(self, NSObjectORMObjectIDKey, ORMObjectID, OBJC_ASSOCIATION_RETAIN);
}

- (ORMStore *)ORMStore
{
    return objc_getAssociatedObject(self, NSObjectORMStoreKey);
}

- (void)setORMStore:(ORMStore *)ORMStore
{
    objc_setAssociatedObject(self, NSObjectORMStoreKey, ORMStore, OBJC_ASSOCIATION_ASSIGN);
}

#pragma mark Persistent & Temporary ORM Values

- (NSMutableDictionary *)persistentORMValues
{
    NSMutableDictionary *cache = objc_getAssociatedObject(self, _cmd);
    if (cache == nil) {
        cache = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN);
    }
    return cache;
}

- (NSMutableDictionary *)temporaryORMValues
{
    NSMutableDictionary *cache = objc_getAssociatedObject(self, _cmd);
    if (cache == nil) {
        cache = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, _cmd, cache, OBJC_ASSOCIATION_RETAIN);
    }
    return cache;
}

#pragma mark ORM Values

- (NSDictionary *)changedORMValues
{
    return [[self temporaryORMValues] copy];
}

- (void)setORMValue:(id)value forKey:(NSString *)key
{
    if (value == nil) {
        if ([[self persistentORMValues] objectForKey:key]) {
            [[self temporaryORMValues] setObject:[NSNull null] forKey:key];
        } else {
            [[self temporaryORMValues] removeObjectForKey:key];
        }
    }
    [[self temporaryORMValues] setObject:value forKey:key];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSObjectORMValuesDidChangeNotification object:self];
}

- (id)ORMValueForKey:(NSString *)key
{
    id value = [[self temporaryORMValues] objectForKey:key];
    if (!value) {
        value = [[self persistentORMValues] objectForKey:key];
    }
    
    if (value == nil && [self ORMObjectID] && [self ORMStore]) {
        ORMAttributeDescription *attributeDescription = [[[[self class] ORM] allProperties] objectForKey:key];
        
        if (attributeDescription) {
            NSError *error = nil;
            NSDictionary *properties = [attributeDescription.managedClass
                                        propertiesOfORMObjectWithPrimaryKey:self.ORMObjectID.primaryKey
                                                                                               inDatabase:self.ORMStore.db
                                                                                                    error:&error];
            
            [[self persistentORMValues] addEntriesFromDictionary:properties];
            
            value = [properties objectForKey:key];
        }
    }
    
    if ([value isEqual:[NSNull null]]) {
        return nil;
    } else {
        return value;
    }
}

#pragma mark -
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
            
            NSMutableSet *uniqueConstraints = [[[self ORM] uniqueConstraints] mutableCopy];
            
            [[[self ORM] properties] enumerateKeysAndObjectsUsingBlock:^(NSString *name, ORMAttributeDescription *attribute, BOOL *stop) {
                
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

+ (ORMPrimaryKey)insertORMObjectProperties:(NSDictionary *)properties
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
    
    [[[[self class] ORM] properties] enumerateKeysAndObjectsUsingBlock:^(NSString *name,
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


+ (BOOL)updateORMObjectWithPrimaryKey:(ORMPrimaryKey)pk
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
    
    [[[[self class] ORM] properties] enumerateKeysAndObjectsUsingBlock:^(NSString *name,
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

+ (BOOL)deleteORMObjectWithPrimaryKey:(ORMPrimaryKey)pk
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

#pragma mark Check Exsitance

+ (BOOL)existsORMObjectWithPrimaryKey:(ORMPrimaryKey)pk
                           inDatabase:(FMDatabase *)database
                                error:(NSError **)error
{
    NSString *statement = [NSString stringWithFormat:@"SELECT _id FROM %@ WHERE _id = :_id", NSStringFromClass(self)];
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

#pragma mark Get Properties

+ (NSDictionary *)propertiesOfORMObjectWithPrimaryKey:(ORMPrimaryKey)pk
                                           inDatabase:(FMDatabase *)database
                                                error:(NSError **)error
{
    return [self propertiesOfORMObjectWithPrimaryKey:pk inDatabase:database error:error includeSuperProperties:NO];
}

+ (NSDictionary *)propertiesOfORMObjectWithPrimaryKey:(ORMPrimaryKey)pk
                                           inDatabase:(FMDatabase *)database
                                                error:(NSError **)error
                               includeSuperProperties:(BOOL)includeSuperProperties
{
    NSString *statement = nil;
    if (includeSuperProperties) {
        NSArray *classes = [[[[self ORM] classHierarchy] reverseObjectEnumerator] allObjects];
        statement = [NSString stringWithFormat:@"SELECT * FROM %@",
                     [classes componentsJoinedByString:@" NATURAL JOIN "]];
    } else {
        statement = [NSString stringWithFormat:@"SELECT * FROM %@", NSStringFromClass(self)];
    }
    statement = [statement stringByAppendingString:@" WHERE _id = :_id"];
    
    NSLog(@"SQL: %@", statement);
    
    FMResultSet *result = [database executeQuery:statement withParameterDictionary:@{@"_id":@(pk)}];
    if (result) {
        if ([result next]) {
            NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
            
            NSDictionary *propertyDesctiptions = nil;
            if (includeSuperProperties) {
                propertyDesctiptions = [[self ORM] allProperties];
            } else {
                propertyDesctiptions = [[self ORM] properties];
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

#pragma mark Enumerate ORM Objects

+ (BOOL)enumerateORMObjectsInDatabase:(FMDatabase *)database
                                error:(NSError **)error
                           enumerator:(void(^)(ORMPrimaryKey pk, Class klass, BOOL *stop))enumerator
{
    return [self enumerateORMObjectsInDatabase:database
                            fetchingProperties:@[]
                                         error:error
                                    enumerator:^(ORMPrimaryKey pk, __unsafe_unretained Class klass, NSDictionary *properties, BOOL *stop) {
                                        enumerator(pk, klass, stop);
                                    }];
}

+ (BOOL)enumerateORMObjectsInDatabase:(FMDatabase *)database
                   fetchingProperties:(NSArray *)propertyNames
                                error:(NSError **)error
                           enumerator:(void(^)(ORMPrimaryKey pk, Class klass, NSDictionary *properties, BOOL *stop))enumerator
{
    return [self enumerateORMObjectsInDatabase:database
                             matchingCondition:nil
                                 withArguments:nil
                            fetchingProperties:propertyNames
                                         error:error
                                    enumerator:enumerator];
}

+ (BOOL)enumerateORMObjectsInDatabase:(FMDatabase *)database
                    matchingCondition:(NSString *)condition
                        withArguments:(NSDictionary *)arguments
                   fetchingProperties:(NSArray *)propertyNames
                                error:(NSError **)error
                           enumerator:(void (^)(ORMPrimaryKey pk, Class klass, NSDictionary *properties, BOOL *stop))enumerator
{
    if (propertyNames == nil) {
        propertyNames = @[];
    }
    
    NSArray *classes = [[[[self ORM] classHierarchy] reverseObjectEnumerator] allObjects];
    
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
            ORMPrimaryKey pk = [[result objectForColumnName:@"_id"] integerValue];
            Class klass = NSClassFromString([result objectForColumnName:@"_class"]);
            
            NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
            [propertyNames enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
                id value = [result objectForColumnName:name];
                [properties setObject:value forKey:name];
            }];
            enumerator(pk, klass, properties, &stop);
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

@implementation NSObject (CocoaORMPrivate)

@dynamic ORMObjectID;
@dynamic ORMStore;
@dynamic persistentORMValues;

- (instancetype)initWithORMObjectID:(ORMObjectID *)objectID inStore:(ORMStore *)store properties:(NSDictionary *)properties
{
    self = [self init];
    if (self) {
        self.ORMObjectID = objectID;
        self.ORMStore = store;
        [[self persistentORMValues] addEntriesFromDictionary:properties];
    }
    return self;
}

- (void)resetChangedORMValues
{
    [[self temporaryORMValues] removeAllObjects];
}

- (void)applyChangedORMValues
{
    [[self temporaryORMValues] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [[self persistentORMValues] setValue:obj forKey:key];
    }];
    [[self temporaryORMValues] removeAllObjects];
}

@end

#pragma mark -

ORMAttributeDescription *
ORMAttribute(Class _class, NSString *name)
{
    ORMClass *ORM = [_class ORM];
    ORMAttributeDescription *attribute = ORM.attribute(name);
    
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

void
ORMUniqueTogether(Class _class, NSArray *propertyNames)
{
    ORMClass *ORM = [_class ORM];
    ORM.unique(propertyNames);
}
