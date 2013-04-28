//
//  CocoaORMTestCase.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

// CocoaORM
#import "CocoaORM.h"
#import "ORMStore+Private.h"

// Test Model
#import "Person.h"
#import "Employee.h"
#import "Chef.h"

@interface CocoaORMTestCase : SenTestCase
@property (nonatomic, strong) ORMStore *store;
@end
