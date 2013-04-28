//
//  NSObject+CocoaORMPrivate.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (CocoaORMPrivate)

- (void)resetChangedORMValues;
- (void)applyChangedORMValues;

@end
