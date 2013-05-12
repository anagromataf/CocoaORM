//
//  ORMEntityDescription.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 05.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <objc/runtime.h>

#import "NSObject+CocoaORM.h"

#import "ORMAttributeDescription.h"
#import "ORMEntityDescription.h"

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

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ORMEntityDescription class]]) {
        ORMEntityDescription *other = object;
        return [self.name isEqual:[other name]];
    }
    return NO;
}

#pragma mark Entity

- (NSString *)name
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
    if (self.superentity) {
        return [[self.superentity entityHierarchy] arrayByAddingObject:self.name];
    } else {
        return @[self.name];
    }
}

#pragma mark Properties

- (ORMAttributeDescription *(^)(NSString *))attribute
{
    return ^(NSString *name) {
        ORMAttributeDescription *attributeDescription = [self.propertyDescriptions objectForKey:name];
        if (!attributeDescription) {
            attributeDescription = [[ORMAttributeDescription alloc] initWithName:name entityDescription:self];
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
    if (self.superentity) {
        NSMutableDictionary *properties = [[self.superentity allProperties] mutableCopy];
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
    if (self.superentity) {
        NSMutableSet *constraints = [[self.superentity allUniqueConstraints] mutableCopy];
        [constraints unionSet:self.uniqueConstraints];
        return constraints;
    } else {
        return self.uniqueConstraints;
    }
}

@end
