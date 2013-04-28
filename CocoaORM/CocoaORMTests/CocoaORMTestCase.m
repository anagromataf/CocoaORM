//
//  CocoaORMTestCase.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMTestCase.h"

@implementation CocoaORMTestCase

- (void)setUp
{
    [super setUp];
    self.store = [[ORMStore alloc] init];
}

- (void)tearDown
{
    self.store = nil;
    [super tearDown];
}

@end
