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

@interface NSObject (CocoaORM)

#pragma mark ORM Descriptions
+ (BOOL)isORMClass;
+ (NSArray *)ORMClassHierarchy;
+ (NSDictionary *)ORMProperties;
+ (NSDictionary *)allORMProperties;

#pragma mark ORM Values
- (id)ORMValueForKey:(NSString *)key;
- (void)setORMValue:(id)value forKey:(NSString *)key;

#pragma mark -
#pragma mark ORM SQL Schemata
+ (BOOL)setupORMSchemataInDatabase:(FMDatabase *)database
                             error:(NSError **)error;

@end

ORMAttributeDescription * ORMAttribute(Class, NSString *name);
