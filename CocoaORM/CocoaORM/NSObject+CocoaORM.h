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

#pragma mark -
#pragma mark SQL Schemata

+ (BOOL)setupORMSchemataInDatabase:(FMDatabase *)database
                             error:(NSError **)error __attribute__ ((deprecated));

#pragma mark Insert, Update & Delete Properties

+ (ORMPrimaryKey)insertORMObjectProperties:(NSDictionary *)properties
                              intoDatabase:(FMDatabase *)database
                                     error:(NSError **)error __attribute__ ((deprecated));

+ (BOOL)updateORMObjectWithPrimaryKey:(ORMPrimaryKey)pk
                       withProperties:(NSDictionary *)properties
                           inDatabase:(FMDatabase *)database
                                error:(NSError **)error __attribute__ ((deprecated));

+ (BOOL)deleteORMObjectWithPrimaryKey:(ORMPrimaryKey)pk
                           inDatabase:(FMDatabase *)database
                                error:(NSError **)error __attribute__ ((deprecated));

#pragma mark Check Exsitance

+ (BOOL)existsORMObjectWithPrimaryKey:(ORMPrimaryKey)pk
                           inDatabase:(FMDatabase *)database
                                error:(NSError **)error __attribute__ ((deprecated));

#pragma mark Get Properties

+ (NSDictionary *)propertiesOfORMObjectWithPrimaryKey:(ORMPrimaryKey)pk
                                           inDatabase:(FMDatabase *)database
                                                error:(NSError **)error __attribute__ ((deprecated));

+ (NSDictionary *)propertiesOfORMObjectWithPrimaryKey:(ORMPrimaryKey)pk
                                           inDatabase:(FMDatabase *)database
                                                error:(NSError **)error
                               includeSuperProperties:(BOOL)includeSuperProperties __attribute__ ((deprecated));

#pragma mark Enumerate ORM Objects

+ (BOOL)enumerateORMObjectsInDatabase:(FMDatabase *)database
                                error:(NSError **)error
                           enumerator:(void(^)(ORMPrimaryKey pk, Class klass, BOOL *stop))enumerator __attribute__ ((deprecated));

+ (BOOL)enumerateORMObjectsInDatabase:(FMDatabase *)database
                   fetchingProperties:(NSArray *)propertyNames
                                error:(NSError **)error
                           enumerator:(void(^)(ORMPrimaryKey pk, Class klass, NSDictionary *properties, BOOL *stop))enumerator __attribute__ ((deprecated));

+ (BOOL)enumerateORMObjectsInDatabase:(FMDatabase *)database
                    matchingCondition:(NSString *)condition
                        withArguments:(NSDictionary *)arguments
                   fetchingProperties:(NSArray *)propertyNames
                                error:(NSError **)error
                           enumerator:(void (^)(ORMPrimaryKey pk, Class klass, NSDictionary *properties, BOOL *stop))enumerator __attribute__ ((deprecated));

@end

ORMAttributeDescription * ORMAttribute(Class klass, NSString *name);
void ORMUniqueTogether(Class klass, NSArray *propertyNames);
