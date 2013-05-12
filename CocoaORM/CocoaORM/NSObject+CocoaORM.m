//
//  NSObject+CocoaORM.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

// Cocoa
#import <objc/runtime.h>
#import <objc/message.h>

// 3rdParty
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseAdditions.h>
#import <JRSwizzle/JRSwizzle.h>

// CocoaORM
#import "NSObject+CocoaORM.h"
#import "ORMEntityDescription.h"
#import "ORMEntitySQLConnector.h"
#import "ORMStore.h"

#pragma mark - ORMObject

const char * NSObjectORMEntityDescriptionKey = "NSObjectORMEntityDescriptionKey";
const char * NSObjectORMObjectKey = "NSObjectORMObjectKey";

@implementation NSObject (CocoaORM)

#pragma mark ORMEntityDescription

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
        
        Method origMethodSignatureForSelector = class_getInstanceMethod(self, @selector(methodSignatureForSelector:));
        class_addMethod(self,
                        @selector(methodSignatureForSelector:),
                        imp_implementationWithBlock(^(id _self, SEL selector){
                            NSMethodSignature *signature = [[_self ORM] methodSignatureForORMSelector:selector];
                            if (!signature) {
                                signature = (NSMethodSignature *)method_invoke(_self, origMethodSignatureForSelector, selector);
                            }
                            return signature;
                        }),
                        method_getTypeEncoding(class_getInstanceMethod(self, @selector(methodSignatureForSelector:))));
        
        Method origForwardInvocation = class_getInstanceMethod(self, @selector(forwardInvocation:));
        class_addMethod(self,
                        @selector(forwardInvocation:),
                        imp_implementationWithBlock(^(id _self, NSInvocation *invocation){
                            BOOL success = [[_self ORM] handleInvocation:invocation];
                            if (!success) {
                                success = (BOOL)method_invoke(_self, origForwardInvocation, invocation);
                            }
                            return success;
                        }),
                        method_getTypeEncoding(class_getInstanceMethod(self, @selector(forwardInvocation:))));
    }
    
    return entityDescription;
}

#pragma mark ORMObject

- (ORMObject *)ORM
{
    ORMObject *ORM = objc_getAssociatedObject(self, NSObjectORMObjectKey);
    if (!ORM) {
        ORM = [[ORMObject alloc] initWithEntityDescription:[[self class] ORMEntityDescription]];
        objc_setAssociatedObject(self, NSObjectORMObjectKey, ORM, OBJC_ASSOCIATION_RETAIN);
        [ORM performSelector:@selector(setManagedObject:) withObject:self];
    }
    return ORM;
}

#pragma mark - Internal

- (id)initWithORMObject:(ORMObject *)anORMObject
{
    self = [self init];
    if (self) {
        objc_setAssociatedObject(self, NSObjectORMObjectKey, anORMObject, OBJC_ASSOCIATION_RETAIN);
        [anORMObject performSelector:@selector(setManagedObject:) withObject:self];
    }
    return self;
}

@end

ORMAttributeDescription *
ORMAttribute(Class _class, NSString *name)
{
    ORMEntityDescription *ORM = [_class ORMEntityDescription];
    ORMAttributeDescription *attribute = ORM.attribute(name);
    return attribute;
}

void
ORMUniqueTogether(Class _class, NSArray *propertyNames)
{
    ORMEntityDescription *ORM = [_class ORMEntityDescription];
    ORM.unique(propertyNames);
}
