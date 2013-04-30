# CocoaORM

Object-relational mapping for Cocoa.

> This project is still under heavy development. A detailed description will be there, after the first feature set is stable.

To get an idea, how it works (and what is already implemented) have a look at the example below.

## Defining the Model

Just define the interface for a class, as you would do it for any _normal_ class.
    
    #import <Foundation/Foundation.h>
    
    @interface Person : NSObject
    @property (nonatomic, readwrite) NSString *firstName;
    @property (nonatomic, readwrite) NSString *lastName;
    @end
    
In the implementation file, specify the properties, which should be stored in the database. There you can also define the column type, if it is required or some unique constraints. 
    
    #import <CocoaORM/CocoaORM.h>
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
    
    @end

## Managing Objects in a Store

To manage Objects in the Store, just create them and add them to the store.

    ORMStore *store = …

    [store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        Person *person = [[Person alloc] init];
        
        person.firstName = @"John";
        person.lastName = @"Example";
                
        [self.store insertObject:person];
        
        return ^(NSError *error){
            
        };
    }];

If you want to update an object, just set the property.

    [store commitTransactionAndWait:^ORMStoreTransactionCompletionHalndler(BOOL *rollback) {
        
        person.firstName = @"Jim";
       
        return nil;
    }];
