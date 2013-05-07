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
#import "ORMConstants.h"
#import "ORMObjectID.h"
#import "ORMStore.h"
#import "ORMAttributeDescription.h"

extern NSString * const NSObjectORMValuesDidChangeNotification;

@interface NSObject (CocoaORM)

#pragma mark ORM Object ID & Store
@property (nonatomic, readonly) ORMObjectID *ORMObjectID;
@property (nonatomic, readonly) ORMStore *ORMStore;

#pragma mark ORM Values
@property (nonatomic, readonly) NSDictionary *changedORMValues;
- (id)ORMValueForKey:(NSString *)key;
- (void)setORMValue:(id)value forKey:(NSString *)key;

@end

ORMAttributeDescription * ORMAttribute(Class klass, NSString *name);
void ORMUniqueTogether(Class klass, NSArray *propertyNames);
