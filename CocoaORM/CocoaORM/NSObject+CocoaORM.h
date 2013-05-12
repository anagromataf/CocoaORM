//
//  NSObject+CocoaORM.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

// Cocoa
#import <Foundation/Foundation.h>

// 3rdParty
#import <FMDB/FMDatabase.h>

// CocoaORM
#import "ORMAttributeDescription.h"
#import "ORMEntityDescription.h"
#import "ORMObject.h"
#import "ORMStore.h"

@interface NSObject (CocoaORM)

#pragma mark ORMEntityDescription
+ (BOOL)isORMClass;
+ (ORMEntityDescription *)ORMEntityDescription;

#pragma mark ORMObject
@property (nonatomic, readonly) ORMObject *ORM;

#pragma mark - Internal
- (id)initWithORMObject:(ORMObject *)anORMObject;

@end

ORMAttributeDescription * ORMAttribute(Class klass, NSString *name);
void ORMUniqueTogether(Class klass, NSArray *propertyNames);
