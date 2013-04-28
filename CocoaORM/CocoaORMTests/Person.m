//
//  Person.m
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "CocoaORM.h"

#import "Person.h"

@implementation Person

+ (void)load
{
    ORMAttribute(self, @"firstName").text().notNull();
    ORMAttribute(self, @"lastName").text().notNull();
}

@dynamic firstName;
@dynamic lastName;

@end
