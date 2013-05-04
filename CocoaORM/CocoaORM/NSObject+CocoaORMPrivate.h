//
//  NSObject+CocoaORMPrivate.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSObject+CocoaORM.h"

@interface NSObject (CocoaORMPrivate)

@property (nonatomic, readwrite) ORMObjectID *ORMObjectID;
@property (nonatomic, readwrite, weak) ORMStore *ORMStore;

- (instancetype)initWithORMObjectID:(ORMObjectID *)objectID inStore:(ORMStore *)store properties:(NSDictionary *)properties;

- (void)resetChangedORMValues;
- (void)applyChangedORMValues;

@property (nonatomic, readonly) NSMutableDictionary *persistentORMValues;

@end
