//
//  Employee.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORM.h"

#import "Employee.h"

@implementation Employee

+ (void)load
{
    ORMAttribute(self, @"position").text().notNull();
    ORMAttribute(self, @"fired").boolean();
    ORMAttribute(self, @"employeeID").integer();
    ORMUnique(self, @[@"employeeID"]);
}

@dynamic position;
@dynamic fired;

@end
