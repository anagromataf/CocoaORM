//
//  ORMObject.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 08.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <objc/runtime.h>

#import "ORMEntityDescription.h"
#import "ORMAttributeDescription.h"

#import "ORMStore+Private.h"

#import "ORMObject.h"

NSString * const ORMObjectDidChangeValuesNotification = @"ORMObjectDidChangeValuesNotification";

@interface ORMObject ()
@property (nonatomic, strong) NSMutableDictionary *temporaryValues;

@property (nonatomic, readonly) NSDictionary *attributeDescriptionsForGetters;
@property (nonatomic, readonly) NSDictionary *attributeDescriptionsForSetters;
@end

@implementation ORMObject

- (id)initWithEntityDescription:(ORMEntityDescription *)entityDescription
{
    self = [super init];
    if (self) {
        _persistentValues = [[NSMutableDictionary alloc] init];
        _temporaryValues = [[NSMutableDictionary alloc] init];
        
        _entityDescription = entityDescription;
        
        NSMutableDictionary *attributeDescriptionsForGetters = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *attributeDescriptionsForSetters = [[NSMutableDictionary alloc] init];
        
        [[entityDescription allProperties] enumerateKeysAndObjectsUsingBlock:^(NSString *name,
                                                                               ORMAttributeDescription *attributeDescription,
                                                                               BOOL *stop) {
            
            [attributeDescriptionsForGetters setObject:attributeDescription
                                                forKey:NSStringFromSelector(attributeDescription.getterSelector)];
            
            [attributeDescriptionsForSetters setObject:attributeDescription
                                                forKey:NSStringFromSelector(attributeDescription.setterSelector)];
        }];
        
        _attributeDescriptionsForGetters = [attributeDescriptionsForGetters copy];
        _attributeDescriptionsForSetters = [attributeDescriptionsForSetters copy];
    }
    return self;
}

#pragma mark Values

- (NSDictionary *)changedValues
{
    return [self.temporaryValues copy];
}

- (void)resetChanges
{
    [self.temporaryValues removeAllObjects];
}

- (void)applyChanges
{
    [self.temporaryValues enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self.persistentValues setValue:obj forKey:key];
    }];
    [self.temporaryValues removeAllObjects];
}

#pragma mark Handle Invocation

- (NSMethodSignature *)methodSignatureForORMSelector:(SEL)aSelector
{
    NSString *selector = NSStringFromSelector(aSelector);
    ORMAttributeDescription *attributeDescription = nil;
    
    attributeDescription = [self.attributeDescriptionsForGetters objectForKey:selector];
    if (attributeDescription) {
        return [NSMethodSignature signatureWithObjCTypes:
                [[NSString stringWithFormat:@"%@@:", attributeDescription.propertyType] UTF8String]];
    }
    
    attributeDescription = [self.attributeDescriptionsForSetters objectForKey:selector];
    if (attributeDescription) {
        return [NSMethodSignature signatureWithObjCTypes:
                [[NSString stringWithFormat:@"v@:%@", attributeDescription.propertyType] UTF8String]];
    }
    
    return nil;
}

- (BOOL)handleInvocation:(NSInvocation *)anInvocation
{
    NSString *selector = NSStringFromSelector([anInvocation selector]);
    ORMAttributeDescription *attributeDescription = nil;
    
    attributeDescription = [self.attributeDescriptionsForGetters objectForKey:selector];
    if (attributeDescription) {
        NSAssert([attributeDescription.propertyType hasPrefix:@"@"],
                 @"Properties with type %@ are not supported.", attributeDescription.propertyType);
        
        id value = [[self temporaryValues] objectForKey:attributeDescription.attributeName];
        if (!value) {
            value = [[self persistentValues] objectForKey:attributeDescription.attributeName];
        }
        
        if (!value) {
            value = [self fetchValueForAttribute:attributeDescription];
        }
        
        if ([value isEqual:[NSNull null]]) {
            value = nil;
        }
        
        [anInvocation setReturnValue:&value];
        [anInvocation retainArguments];
        
        return YES;
    }
    
    attributeDescription = [self.attributeDescriptionsForSetters objectForKey:selector];
    if (attributeDescription) {
        NSAssert([attributeDescription.propertyType hasPrefix:@"@"],
                 @"Properties with type %@ are not supported.", attributeDescription.propertyType);
        __unsafe_unretained id value = nil;
        [anInvocation getArgument:&value atIndex:2];
        
        if (value == nil) {
            if ([self.persistentValues objectForKey:attributeDescription.attributeName]) {
                [self.temporaryValues setObject:[NSNull null]
                                         forKey:attributeDescription.attributeName];
            } else {
                [self.temporaryValues removeObjectForKey:attributeDescription.attributeName];
            }
        } else {
            [self.temporaryValues setObject:value
                                     forKey:attributeDescription.attributeName];
        }
        
        NSNotification *notification = [NSNotification notificationWithName:ORMObjectDidChangeValuesNotification
                                                                     object:self];
        [[NSNotificationQueue defaultQueue] enqueueNotification:notification
                                                   postingStyle:NSPostNow];
        
        return YES;
    }
    
    return NO;
}

- (id)fetchValueForAttribute:(ORMAttributeDescription *)attributeDescription
{
    NSError *error = nil;
    
    ORMEntitySQLConnector *connector = [ORMEntitySQLConnector connectorWithEntityDescription:attributeDescription.entityDescription];
    
    NSDictionary *properties = [connector propertiesOfEntityWithEntityID:self.objectID.entityID
                                                              inDatabase:self.store.db
                                                                   error:&error];
    
    [self.persistentValues addEntriesFromDictionary:properties];
    
    return [properties objectForKey:attributeDescription.attributeName];
}

@end
