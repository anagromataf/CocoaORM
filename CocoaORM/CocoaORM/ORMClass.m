//
//  ORMClass.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 05.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <objc/runtime.h>

#import "ORMAttributeDescription.h"
#import "ORMClass.h"

const char * NSObjectORMClassKey = "NSObjectORMClassKey";

@interface ORMClass ()
@property (nonatomic, readonly) NSMutableDictionary *propertyDescriptions;
@property (nonatomic, readonly) NSMutableSet *uniqueTogetherConstraints;
@end

@implementation ORMClass

#pragma mark Life-cycle

- (id)initWithClass:(Class)managedClass
{
    self = [super init];
    if (self) {
        _managedClass = managedClass;
        _propertyDescriptions = [[NSMutableDictionary alloc] init];
        _uniqueTogetherConstraints = [[NSMutableSet alloc] init];
    }
    return self;
}

#pragma mark Managed Class

- (NSArray *)classHierarchy
{
    if ([[self.managedClass superclass] isORMClass]) {
        return [[[[self.managedClass superclass] ORM] classHierarchy] arrayByAddingObject:self.managedClass];
    } else {
        return @[self.managedClass];
    }
}

- (NSString *)entityName
{
    return NSStringFromClass(self.managedClass);
}

- (NSArray *)entityHierarchy
{
    if ([[self.managedClass superclass] isORMClass]) {
        return [[[[self.managedClass superclass] ORM] entityHierarchy] arrayByAddingObject:self.entityName];
    } else {
        return @[self.entityName];
    }
}

#pragma mark Properties

- (ORMAttributeDescription *(^)(NSString *))attribute
{
    return ^(NSString *name) {
        ORMAttributeDescription *attributeDescription = [self.propertyDescriptions objectForKey:name];
        if (!attributeDescription) {
            attributeDescription = [[ORMAttributeDescription alloc] initWithName:name ORMClass:self];
            [self.propertyDescriptions setObject:attributeDescription forKey:name];
        }
        return attributeDescription;
    };
}

- (NSDictionary *)properties
{
    return [self.propertyDescriptions copy];
}

- (NSDictionary *)allProperties
{
    if ([[self.managedClass superclass] isORMClass]) {
        NSMutableDictionary *properties = [[[[self.managedClass superclass] ORM] allProperties] mutableCopy];
        [properties addEntriesFromDictionary:self.properties];
        return properties;
    } else {
        return self.properties;
    }
}

#pragma mar Constraints

- (void (^)(NSArray *))unique
{
    return ^(NSArray *names) {
        [self.uniqueTogetherConstraints addObject:[NSSet setWithArray:names]];
    };
}

- (NSSet *)uniqueConstraints
{
    return [self.uniqueTogetherConstraints copy];
}

- (NSSet *)allUniqueConstraints
{
    if ([[self.managedClass superclass] isORMClass]) {
        NSMutableSet *constraints = [[[[self.managedClass superclass] ORM] allUniqueConstraints] mutableCopy];
        [constraints unionSet:self.uniqueConstraints];
        return constraints;
    } else {
        return self.uniqueConstraints;
    }
}

@end

#pragma mark -

@implementation NSObject (ORMClass)

+ (BOOL)isORMClass
{
    if (self == [NSObject class]) {
        return NO;
    } else if (objc_getAssociatedObject(self, NSObjectORMClassKey) != nil) {
        return YES;
    } else {
        return [[self superclass] isORMClass];
    }
}

+ (ORMClass *)ORM
{
    ORMClass *ORM = objc_getAssociatedObject(self, NSObjectORMClassKey);
    if (!ORM) {
        ORM = [[ORMClass alloc] initWithClass:[self class]];
        objc_setAssociatedObject(self, NSObjectORMClassKey, ORM, OBJC_ASSOCIATION_RETAIN);
    }
    return ORM;
}

@end
