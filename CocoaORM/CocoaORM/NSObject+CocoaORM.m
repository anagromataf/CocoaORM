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
