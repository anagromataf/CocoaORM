//
//  ORMEntityDescription.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 05.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <objc/runtime.h>

#import "ORMAttributeDescription.h"
#import "ORMEntityDescription.h"

const char * NSObjectORMEntityDescriptionKey = "NSObjectORMEntityDescriptionKey";

@interface ORMEntityDescription ()
@property (nonatomic, readonly) NSMutableDictionary *propertyDescriptions;
@property (nonatomic, readonly) NSMutableSet *uniqueTogetherConstraints;
@end

@implementation ORMEntityDescription

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

#pragma mark Entity

- (NSString *)entityName
{
    return NSStringFromClass(self.managedClass);
}

- (ORMEntityDescription *)superentity
{
    if ([[self.managedClass superclass] isORMClass]) {
        return [[self.managedClass superclass] ORMEntityDescription];
    } else {
        return nil;
    }
}

- (NSArray *)entityHierarchy
{
    if ([[self.managedClass superclass] isORMClass]) {
        return [[[[self.managedClass superclass] ORMEntityDescription] entityHierarchy] arrayByAddingObject:self.entityName];
    } else {
        return @[self.entityName];
    }
}

#pragma mark Managed Class

- (NSArray *)classHierarchy
{
    if ([[self.managedClass superclass] isORMClass]) {
        return [[[[self.managedClass superclass] ORMEntityDescription] classHierarchy] arrayByAddingObject:self.managedClass];
    } else {
        return @[self.managedClass];
    }
}

#pragma mark Properties

- (ORMAttributeDescription *(^)(NSString *))attribute
{
    return ^(NSString *name) {
        ORMAttributeDescription *attributeDescription = [self.propertyDescriptions objectForKey:name];
        if (!attributeDescription) {
            attributeDescription = [[ORMAttributeDescription alloc] initWithName:name ORMEntityDescription:self];
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
        NSMutableDictionary *properties = [[[[self.managedClass superclass] ORMEntityDescription] allProperties] mutableCopy];
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
        NSMutableSet *constraints = [[[[self.managedClass superclass] ORMEntityDescription] allUniqueConstraints] mutableCopy];
        [constraints unionSet:self.uniqueConstraints];
        return constraints;
    } else {
        return self.uniqueConstraints;
    }
}

@end

#pragma mark -

@implementation NSObject (ORMEntityDescription)

+ (BOOL)isORMClass
{
    if (self == [NSObject class]) {
        return NO;
    } else if (objc_getAssociatedObject(self, NSObjectORMEntityDescriptionKey) != nil) {
        return YES;
    } else {
        return [[self superclass] isORMClass];
    }
}

+ (ORMEntityDescription *)ORMEntityDescription
{
    ORMEntityDescription *entityDescription = objc_getAssociatedObject(self, NSObjectORMEntityDescriptionKey);
    if (!entityDescription) {
        entityDescription = [[ORMEntityDescription alloc] initWithClass:[self class]];
        objc_setAssociatedObject(self, NSObjectORMEntityDescriptionKey, entityDescription, OBJC_ASSOCIATION_RETAIN);
    }
    return entityDescription;
}

@end
