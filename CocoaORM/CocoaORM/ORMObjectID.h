//
//  ORMObjectID.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 29.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ORMEntitySQLConnector.h"

@class ORMEntityDescription;

@interface ORMObjectID : NSObject <NSCopying>

#pragma mark Life-cycle
- (id)initWithEntityDescription:(ORMEntityDescription *)entityDescription
                       entityID:(ORMEntityID)entityID;

#pragma mark Properties
@property (nonatomic, readonly) ORMEntityDescription *entityDescription;
@property (nonatomic, readonly) ORMEntityID entityID;

@end
