//
//  ORMClass.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 05.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ORMAttributeDescription;
@class ORMClass;

@interface NSObject (ORMClass)
+ (BOOL)isORMClass;
+ (ORMClass *)ORM;
@end

@interface ORMClass : NSObject

#pragma mark Life-cycle
- (id)initWithClass:(Class)managedClass;

#pragma mark Managed Class
@property (nonatomic, readonly) Class managedClass;
@property (nonatomic, readonly) NSArray *classHierarchy;
@property (nonatomic, readonly) NSString *entityName;
@property (nonatomic, readonly) NSArray *entityHierarchy;

#pragma mark Properties
@property (nonatomic, readonly) ORMAttributeDescription *(^attribute)(NSString *name);
@property (nonatomic, readonly) NSDictionary *properties;
@property (nonatomic, readonly) NSDictionary *allProperties;

#pragma mark Constraints
@property (nonatomic, readonly) void (^unique)(NSArray *names);
@property (nonatomic, readonly) NSSet *uniqueConstraints;
@property (nonatomic, readonly) NSSet *allUniqueConstraints;

@end
