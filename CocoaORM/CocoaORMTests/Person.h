//
//  Person.h
//  CocoaORM
//
//  Created by Tobias Kräntzer on 28.04.13.
//  Copyright (c) 2013 Tobias Kräntzer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject
@property (nonatomic, readwrite) NSString *firstName;
@property (nonatomic, readwrite) NSString *lastName;

- (id)initWithFirstName:(NSString *)firstName lastName:(NSString *)lastName;

@end
