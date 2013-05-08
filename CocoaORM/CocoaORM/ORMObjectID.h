//
//  ORMObjectID.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 29.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ORMEntitySQLConnector.h"

@interface ORMObjectID : NSObject <NSCopying>
@property (nonatomic, readonly) Class ORMClass;
@property (nonatomic, readonly) ORMEntityID entityID;

- (id)initWithClass:(Class)aClass primaryKey:(ORMEntityID)primaryKey;

@end
