//
//  CocoaORMDatabaseTestCase.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 05.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMTestCase.h"

@interface CocoaORMDatabaseTestCase : CocoaORMTestCase

@property (nonatomic, strong) ORMEntitySQLConnector *personConnector;
@property (nonatomic, strong) ORMEntitySQLConnector *employeeConnector;
@property (nonatomic, strong) ORMEntitySQLConnector *chefConnector;

@end
