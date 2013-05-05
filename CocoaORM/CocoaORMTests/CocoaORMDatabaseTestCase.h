//
//  CocoaORMDatabaseTestCase.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 05.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMTestCase.h"

@interface CocoaORMDatabaseTestCase : CocoaORMTestCase

@property (nonatomic, strong) ORMClassMapping *personMapping;
@property (nonatomic, strong) ORMClassMapping *employeeMapping;
@property (nonatomic, strong) ORMClassMapping *chefMapping;

@end
