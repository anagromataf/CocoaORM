//
//  ORMObject.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 08.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ORMEntityDescription;

@interface ORMObject : NSObject

#pragma mark Entity Description
@property (nonatomic, readonly) ORMEntityDescription *entityDescription;

#pragma mark Values
- (void)setManagedValue:(id)value forKey:(NSString *)key;
- (id)managedValueForKey:(NSString *)key;
@property (nonatomic, readonly) NSDictionary *changedValues;

@end
