//
//  ORMObjectID.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 29.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "ORMObjectID.h"

@implementation ORMObjectID

- (id)initWithClass:(Class)aClass primaryKey:(ORMEntityID)entityID
{
    self = [super init];
    if (self) {
        _ORMClass = aClass;
        _entityID = entityID;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[ORMObjectID allocWithZone:zone] initWithClass:self.ORMClass primaryKey:self.entityID];
}

- (NSUInteger)hash
{
    return self.entityID;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ORMObjectID class]]) {
        ORMObjectID *other = object;
        
        if (self.entityID != other.entityID) {
            return NO;
        }
        
        if (self.ORMClass != other.ORMClass) {
            return NO;
        }
        
        return YES;
    }
    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<ORMObjectID: %p %@ %lld>", self, self.ORMClass, self.entityID];
}

@end
