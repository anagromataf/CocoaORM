//
//  ORMObjectID.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 29.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ORMEntitySQLConnector.h"
#import "ORMEntityDescription.h"

@interface ORMObjectID : NSObject <NSCopying>
@property (nonatomic, readonly) ORMEntityDescription *entityDescription;
@property (nonatomic, readonly) ORMEntityID entityID;

- (id)initWithEntityDescription:(ORMEntityDescription *)entityDescription
                       entityID:(ORMEntityID)entityID;

@end
