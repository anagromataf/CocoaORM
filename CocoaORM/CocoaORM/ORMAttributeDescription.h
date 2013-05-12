//
//  ORMAttributeDescription.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ORMEntityDescription;

@interface ORMAttributeDescription : NSObject

#pragma mark Life-cycle
- (id)initWithPropertyName:(NSString *)propertyName
         entityDescription:(ORMEntityDescription *)ORMEntityDescription;

#pragma mark Objective-C Property
@property (nonatomic, readonly) NSString *propertyName;
@property (nonatomic, readonly) NSString *propertyType;
@property (nonatomic, readonly) SEL propertyGetterSelector;
@property (nonatomic, readonly) SEL propertySetterSelector;

#pragma mark Entity Description
@property (nonatomic, readonly) ORMEntityDescription *entityDescription;

#pragma mark Attribute Configuration
@property (nonatomic, readonly) ORMAttributeDescription *(^integer)();
@property (nonatomic, readonly) ORMAttributeDescription *(^real)();
@property (nonatomic, readonly) ORMAttributeDescription *(^text)();
@property (nonatomic, readonly) ORMAttributeDescription *(^blob)();
@property (nonatomic, readonly) ORMAttributeDescription *(^boolean)();
@property (nonatomic, readonly) ORMAttributeDescription *(^notNull)();
@property (nonatomic, readonly) ORMAttributeDescription *(^unique)();

#pragma mark Column Specification
@property (nonatomic, readonly) NSString *columnType;
@property (nonatomic, readonly) BOOL columnRequired;
@property (nonatomic, readonly) BOOL columnUnique;

@end
