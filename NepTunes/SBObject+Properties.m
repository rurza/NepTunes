//
//  SBObject+Properties.m
//  NepTunes
//
//  Created by Adam Różyński on 03/10/2018.
//  Copyright © 2018 micropixels. All rights reserved.
//

#import "SBObject+Properties.h"
#import <objc/runtime.h>

@implementation SBObject (Properties)

- (void)logProperties
{
    NSLog(@"----------------------------------------------- Properties for object %@", self);
    
    @autoreleasepool {
        unsigned int numberOfProperties = 0;
        objc_property_t *propertyArray = class_copyPropertyList([self class], &numberOfProperties);
        for (NSUInteger i = 0; i < numberOfProperties; i++) {
            objc_property_t property = propertyArray[i];
            NSString *name = [[NSString alloc] initWithUTF8String:property_getName(property)];
            NSLog(@"Property %@ Value: %@", name, [self valueForKey:name]);
        }
        free(propertyArray);
    }
    NSLog(@"-----------------------------------------------");
}

@end
