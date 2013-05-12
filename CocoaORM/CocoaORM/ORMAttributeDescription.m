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
@property (nonatomic, readwrite) NSString *attributeName;
@property (nonatomic, readwrite, weak) ORMEntityDescription *entityDescription;

@property (nonatomic, readwrite) NSString *typeName;
@property (nonatomic, readwrite) BOOL required;
@property (nonatomic, readwrite) BOOL uniqueProperty;

@end

@implementation ORMAttributeDescription

- (id)initWithName:(NSString *)name entityDescription:(ORMEntityDescription *)entityDescription;
{
    self = [super init];
    if (self) {
        _attributeName = name;
        _entityDescription = entityDescription;
        _typeName = @"TEXT";
        
        objc_property_t prop = class_getProperty(entityDescription.managedClass, [name UTF8String]);
    
        // Setter
        char *setterName = property_copyAttributeValue(prop, "S");
        if (setterName) {
            _setterSelector = NSSelectorFromString([NSString stringWithUTF8String:setterName]);
            free(setterName);
        } else {
            NSString *selectorString = [name stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                                                     withString:[[name substringToIndex:1] uppercaseString]];
            selectorString = [NSString stringWithFormat:@"set%@:", selectorString];
            _setterSelector = NSSelectorFromString(selectorString);
        }
        
        // Getter
        char *getterName = property_copyAttributeValue(prop, "G");
        if (getterName) {
            _getterSelector = NSSelectorFromString([NSString stringWithUTF8String:getterName]);
            free(getterName);
        } else {
            _getterSelector = NSSelectorFromString(name);
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

- (Class)managedClass
{
    return self.entityDescription.managedClass;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<ORMAttributeDescription %p name:%@ type:%@ getter=%@, setter=%@>",
            self,
            self.attributeName,
            self.propertyType,
            NSStringFromSelector(self.getterSelector),
            NSStringFromSelector(self.setterSelector)];
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
