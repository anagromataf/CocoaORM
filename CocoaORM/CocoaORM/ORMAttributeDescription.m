//
//  ORMAttributeDescription.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "ORMAttributeDescription.h"

@interface ORMAttributeDescription ()
@property (nonatomic, readwrite) NSString *attributeName;
@property (nonatomic, readwrite) NSString *typeName;
@property (nonatomic, readwrite) BOOL required;
@end

@implementation ORMAttributeDescription

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _attributeName = name;
        _typeName = @"TEXT";
    }
    return self;
}

- (ORMAttributeDescription *(^)())integer
{
    return ^{
        self.typeName = @"INTEGER";
        return self;
    };
}

- (ORMAttributeDescription *(^)())real
{
    return ^{
        self.typeName = @"REAL";
        return self;
    };
}

- (ORMAttributeDescription *(^)())text
{
    return ^{
        self.typeName = @"TEXT";
        return self;
    };
}

- (ORMAttributeDescription *(^)())blob
{
    return ^{
        self.typeName = @"BLOB";
        return self;
    };
}

- (ORMAttributeDescription *(^)())boolean
{
    return ^{
        self.typeName = @"BOOLEAN";
        return self;
    };
}

- (ORMAttributeDescription *(^)())notNull
{
    return ^{
        self.required = YES;
        return self;
    };
}

@end
