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

- (void)resetChangedORMValues;
- (void)applyChangedORMValues;

@end
