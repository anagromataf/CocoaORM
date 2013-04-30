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
    ORMUniqueTogether(self, @[@"firstName", @"lastName"]);
}

@dynamic firstName;
@dynamic lastName;

- (id)initWithFirstName:(NSString *)firstName lastName:(NSString *)lastName
{
    self = [self init];
    if (self) {
        self.firstName = firstName;
        self.lastName = lastName;
    }
    return self;
}

@end
