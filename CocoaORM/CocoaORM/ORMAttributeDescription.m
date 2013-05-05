//
//  ORMAttributeDescription.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "ORMClass.h"
#import "ORMAttributeDescription.h"

@interface ORMAttributeDescription ()
@property (nonatomic, readwrite) NSString *attributeName;
@property (nonatomic, readwrite, weak) ORMClass *ORMClass;

@property (nonatomic, readwrite) NSString *typeName;
@property (nonatomic, readwrite) BOOL required;
@property (nonatomic, readwrite) BOOL uniqueProperty;
@end

@implementation ORMAttributeDescription

- (id)initWithName:(NSString *)name ORMClass:(ORMClass *)ORMClass;
{
    self = [super init];
    if (self) {
        _attributeName = name;
        _ORMClass = ORMClass;
        _typeName = @"TEXT";
    }
    return self;
}

- (Class)managedClass
{
    return self.ORMClass.managedClass;
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

- (ORMAttributeDescription *(^)())unique
{
    return ^{
        self.uniqueProperty = YES;
        return self;
    };
}

@end
