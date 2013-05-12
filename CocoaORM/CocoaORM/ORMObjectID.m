//
//  ORMObjectID.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 29.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "ORMEntityDescription.h"

#import "ORMObjectID.h"

@implementation ORMObjectID

#pragma mark Life-cycle

- (id)initWithEntityDescription:(ORMEntityDescription *)entityDescription
                       entityID:(ORMEntityID)entityID
{
    self = [super init];
    if (self) {
        _entityDescription = entityDescription;
        _entityID = entityID;
    }
    return self;
}

#pragma mark NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<ORMObjectID: %p %@ %lld>", self, self.entityDescription.name, self.entityID];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ORMObjectID class]]) {
        ORMObjectID *other = object;
        
        if (self.entityID != other.entityID) {
            return NO;
        }
        
        if (![self.entityDescription isEqual:other.entityDescription]) {
            return NO;
        }
        
        return YES;
    }
    return NO;
}

- (NSUInteger)hash
{
    return self.entityID;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return [[ORMObjectID allocWithZone:zone] initWithEntityDescription:self.entityDescription
                                                              entityID:self.entityID];
}


@end
