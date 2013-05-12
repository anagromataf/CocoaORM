//
//  NSObject+CocoaORM.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

// Cocoa
#import <Foundation/Foundation.h>

@class ORMEntityDescription;
@class ORMAttributeDescription;
@class ORMObject;

@interface NSObject (CocoaORM)

#pragma mark ORMEntityDescription
+ (BOOL)isORMClass;
+ (ORMEntityDescription *)ORMEntityDescription;

#pragma mark ORMObject
@property (nonatomic, readonly) ORMObject *ORM;

@end

ORMAttributeDescription * ORMAttribute(Class klass, NSString *name);
void ORMUniqueTogether(Class klass, NSArray *propertyNames);
