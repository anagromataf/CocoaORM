//
//  ORMEntitySQLConnector.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 05.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@class ORMEntityDescription;

typedef int64_t ORMEntityID;


@interface ORMEntitySQLConnector : NSObject

+ (instancetype)connectorWithEntityDescription:(ORMEntityDescription *)entityDescription;

#pragma mark Life-cycle
- (id)initWithEntityDescription:(ORMEntityDescription *)entityDescription;

#pragma mark Mapped Class
@property (nonatomic, readonly) ORMEntityDescription *entityDescription;

#pragma mark Setup Schemata for Entity
- (BOOL)setupSchemataInDatabase:(FMDatabase *)database
                          error:(NSError **)error;

#pragma mark Insert, Update & Delete Entity
- (ORMEntityID)insertEntityWithProperties:(NSDictionary *)properties
                             intoDatabase:(FMDatabase *)database
                                    error:(NSError **)error;

- (BOOL)updateEntityWithEntityID:(ORMEntityID)eid
                  withProperties:(NSDictionary *)properties
                      inDatabase:(FMDatabase *)database
                           error:(NSError **)error;

- (BOOL)deleteEntityWithEntityID:(ORMEntityID)eid
                      inDatabase:(FMDatabase *)database
                           error:(NSError **)error;

#pragma mark Check if Entity exists
- (BOOL)existsEntityWithEntityID:(ORMEntityID)eid
                      inDatabase:(FMDatabase *)database
                           error:(NSError **)error;

#pragma mark Get Properties of Entity
- (NSDictionary *)propertiesOfEntityWithEntityID:(ORMEntityID)eid
                                      inDatabase:(FMDatabase *)database
                                           error:(NSError **)error;

- (NSDictionary *)propertiesOfEntityWithEntityID:(ORMEntityID)eid
                                      inDatabase:(FMDatabase *)database
                                           error:(NSError **)error
                          includeSuperProperties:(BOOL)includeSuperProperties;

#pragma mark Enumerate Entities
- (BOOL)enumerateEntitiesInDatabase:(FMDatabase *)database
                              error:(NSError **)error
                         enumerator:(void(^)(ORMEntityID eid, Class klass, BOOL *stop))enumerator;

- (BOOL)enumerateEntitiesInDatabase:(FMDatabase *)database
                 fetchingProperties:(NSArray *)propertyNames
                              error:(NSError **)error
                         enumerator:(void(^)(ORMEntityID eid, Class klass, NSDictionary *properties, BOOL *stop))enumerator;

- (BOOL)enumerateEntitiesInDatabase:(FMDatabase *)database
                  matchingCondition:(NSString *)condition
                      withArguments:(NSDictionary *)arguments
                 fetchingProperties:(NSArray *)propertyNames
                              error:(NSError **)error
                         enumerator:(void (^)(ORMEntityID eid, Class klass, NSDictionary *properties, BOOL *stop))enumerator;

@end
