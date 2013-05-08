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
#import "ORMEntityDescription.h"
#import "ORMEntitySQLConnector.h"
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
        ORMAttributeDescription *attributeDescription = [[[[self class] ORMEntityDescription] allProperties] objectForKey:key];
        
        if (attributeDescription) {
            NSError *error = nil;
            
            ORMEntitySQLConnector *mapping = [ORMEntitySQLConnector connectorWithEntityDescription:attributeDescription.ORMEntityDescription];
            
            NSDictionary *properties = [mapping propertiesOfEntityWithEntityID:self.ORMObjectID.entityID
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
    ORMEntityDescription *ORM = [_class ORMEntityDescription];
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
    ORMEntityDescription *ORM = [_class ORMEntityDescription];
    ORM.unique(propertyNames);
}
