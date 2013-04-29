//
//  ORMObjectID.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 29.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ORMConstants.h"

@interface ORMObjectID : NSObject
@property (nonatomic, readonly) Class ORMClass;
@property (nonatomic, readonly) ORMPrimaryKey primaryKey;

- (id)initWithClass:(Class)aClass primaryKey:(ORMPrimaryKey)primaryKey;

@end
