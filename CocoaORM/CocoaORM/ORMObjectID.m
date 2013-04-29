//
//  ORMObjectID.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 29.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "ORMObjectID.h"

@implementation ORMObjectID

- (id)initWithClass:(Class)aClass primaryKey:(ORMPrimaryKey)primaryKey
{
    self = [super init];
    if (self) {
        _ORMClass = aClass;
        _primaryKey = primaryKey;
    }
    return self;
}

@end
