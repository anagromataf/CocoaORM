//
//  Employee.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import "Person.h"

@interface Employee : Person
@property (nonatomic, readwrite) NSString *position;
@property (nonatomic, readwrite) NSNumber *fired;
@end
