//
//  CocoaORMDatabaseTestCase.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 05.05.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORMDatabaseTestCase.h"

@implementation CocoaORMDatabaseTestCase

- (void)setUp
{
    [super setUp];
    
    self.personConnector = [ORMEntitySQLConnector connectorWithEntityDescription:[Person ORMEntityDescription]];
    self.employeeConnector = [ORMEntitySQLConnector connectorWithEntityDescription:[Employee ORMEntityDescription]];
    self.chefConnector = [ORMEntitySQLConnector connectorWithEntityDescription:[Chef ORMEntityDescription]];    
}

@end
