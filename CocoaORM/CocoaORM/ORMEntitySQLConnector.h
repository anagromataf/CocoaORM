//
//  ORMEntitySQLConnector.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 05.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ORMConstants.h"

@class FMDatabase;

@interface ORMEntitySQLConnector : NSObject

+ (instancetype)mappingForClass:(Class)mappedClass;

#pragma mark Life-cycle
- (id)initWithClass:(Class)mappedClass;

#pragma mark Mapped Class
@property (nonatomic, readonly) Class mappedClass;

#pragma mark Setup Schemata for Entity
- (BOOL)setupSchemataInDatabase:(FMDatabase *)database
                          error:(NSError **)error;

#pragma mark Insert, Update & Delete Entity
- (ORMPrimaryKey)insertEntityWithProperties:(NSDictionary *)properties
                               intoDatabase:(FMDatabase *)database
                                      error:(NSError **)error;

- (BOOL)updateEntityWithPrimaryKey:(ORMPrimaryKey)pk
                    withProperties:(NSDictionary *)properties
                        inDatabase:(FMDatabase *)database
                             error:(NSError **)error;

- (BOOL)deleteEntityWithPrimaryKey:(ORMPrimaryKey)pk
                        inDatabase:(FMDatabase *)database
                             error:(NSError **)error;

#pragma mark Check if Entity exists
- (BOOL)existsEntityWithPrimaryKey:(ORMPrimaryKey)pk
                        inDatabase:(FMDatabase *)database
                             error:(NSError **)error;

#pragma mark Get Properties of Entity
- (NSDictionary *)propertiesOfEntityWithPrimaryKey:(ORMPrimaryKey)pk
                                        inDatabase:(FMDatabase *)database
                                             error:(NSError **)error;

- (NSDictionary *)propertiesOfEntityWithPrimaryKey:(ORMPrimaryKey)pk
                                        inDatabase:(FMDatabase *)database
                                             error:(NSError **)error
                            includeSuperProperties:(BOOL)includeSuperProperties;

#pragma mark Enumerate Entities
- (BOOL)enumerateEntitiesInDatabase:(FMDatabase *)database
                              error:(NSError **)error
                         enumerator:(void(^)(ORMPrimaryKey pk, Class klass, BOOL *stop))enumerator;

- (BOOL)enumerateEntitiesInDatabase:(FMDatabase *)database
                 fetchingProperties:(NSArray *)propertyNames
                              error:(NSError **)error
                         enumerator:(void(^)(ORMPrimaryKey pk, Class klass, NSDictionary *properties, BOOL *stop))enumerator;

- (BOOL)enumerateEntitiesInDatabase:(FMDatabase *)database
                  matchingCondition:(NSString *)condition
                      withArguments:(NSDictionary *)arguments
                 fetchingProperties:(NSArray *)propertyNames
                              error:(NSError **)error
                         enumerator:(void (^)(ORMPrimaryKey pk, Class klass, NSDictionary *properties, BOOL *stop))enumerator;

@end
