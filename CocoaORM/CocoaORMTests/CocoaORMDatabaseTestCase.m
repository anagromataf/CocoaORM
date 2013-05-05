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
    
    self.personMapping = [ORMClassMapping mappingForClass:[Person class]];
    self.employeeMapping = [ORMClassMapping mappingForClass:[Employee class]];
    self.chefMapping = [ORMClassMapping mappingForClass:[Chef class]];
    
}

@end
