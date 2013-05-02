//
//  ORMAttributeDescription.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORMAttributeDescription : NSObject

- (id)initWithName:(NSString *)name ORMClass:(Class)aClass;

@property (nonatomic, readonly) NSString *attributeName;
@property (nonatomic, readonly) Class ORMClass;

@property (nonatomic, readonly) ORMAttributeDescription *(^integer)();
@property (nonatomic, readonly) ORMAttributeDescription *(^real)();
@property (nonatomic, readonly) ORMAttributeDescription *(^text)();
@property (nonatomic, readonly) ORMAttributeDescription *(^blob)();
@property (nonatomic, readonly) ORMAttributeDescription *(^boolean)();
@property (nonatomic, readonly) ORMAttributeDescription *(^notNull)();
@property (nonatomic, readonly) ORMAttributeDescription *(^unique)();

@property (nonatomic, readonly) NSString *typeName;
@property (nonatomic, readonly) BOOL required;
@property (nonatomic, readonly) BOOL uniqueProperty;

@end
