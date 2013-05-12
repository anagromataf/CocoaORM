//
//  ORMAttributeDescription.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <objc/runtime.h>

#import "ORMEntityDescription.h"
#import "ORMAttributeDescription.h"

@interface ORMAttributeDescription ()
@property (nonatomic, readwrite, weak) ORMEntityDescription *entityDescription;
@property (nonatomic, readwrite) NSString *columnType;
@property (nonatomic, readwrite) BOOL columnRequired;
@property (nonatomic, readwrite) BOOL columnUnique;
@end

@implementation ORMAttributeDescription

#pragma mark Life-cycle
- (id)initWithPropertyName:(NSString *)propertyName entityDescription:(ORMEntityDescription *)entityDescription;
{
    self = [super init];
    if (self) {
        _propertyName = propertyName;
        _entityDescription = entityDescription;
        _columnType = @"TEXT";
        
        objc_property_t prop = class_getProperty(entityDescription.managedClass, [propertyName UTF8String]);
    
        // Setter
        char *setterName = property_copyAttributeValue(prop, "S");
        if (setterName) {
            _propertySetterSelector = NSSelectorFromString([NSString stringWithUTF8String:setterName]);
            free(setterName);
        } else {
            NSString *selectorString = [propertyName stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                                             withString:[[propertyName substringToIndex:1] uppercaseString]];
            selectorString = [NSString stringWithFormat:@"set%@:", selectorString];
            _propertySetterSelector = NSSelectorFromString(selectorString);
        }
        
        // Getter
        char *getterName = property_copyAttributeValue(prop, "G");
        if (getterName) {
            _propertyGetterSelector = NSSelectorFromString([NSString stringWithUTF8String:getterName]);
            free(getterName);
        } else {
            _propertyGetterSelector = NSSelectorFromString(propertyName);
        }
        
        // Type
        char *type = property_copyAttributeValue(prop, "T");
        if (type) {
            _propertyType = [NSString stringWithUTF8String:type];
            free(type);
        }
    }
    return self;
}

#pragma mark Attribute Configuration

- (ORMAttributeDescription *(^)())integer
{
    return ^{
        self.columnType = @"INTEGER";
        return self;
    };
}

- (ORMAttributeDescription *(^)())real
{
    return ^{
        self.columnType = @"REAL";
        return self;
    };
}

- (ORMAttributeDescription *(^)())text
{
    return ^{
        self.columnType = @"TEXT";
        return self;
    };
}

- (ORMAttributeDescription *(^)())blob
{
    return ^{
        self.columnType = @"BLOB";
        return self;
    };
}

- (ORMAttributeDescription *(^)())boolean
{
    return ^{
        self.columnType = @"BOOLEAN";
        return self;
    };
}

- (ORMAttributeDescription *(^)())notNull
{
    return ^{
        self.columnRequired = YES;
        return self;
    };
}

- (ORMAttributeDescription *(^)())unique
{
    return ^{
        self.columnUnique = YES;
        return self;
    };
}

#pragma mark NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<ORMAttributeDescription %p name:%@ type:%@ getter=%@, setter=%@>",
            self,
            self.propertyName,
            self.propertyType,
            NSStringFromSelector(self.propertyGetterSelector),
            NSStringFromSelector(self.propertySetterSelector)];
}

@end
