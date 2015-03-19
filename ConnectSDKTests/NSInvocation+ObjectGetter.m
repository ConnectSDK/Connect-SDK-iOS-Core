//
//  NSInvocation+ObjectGetter.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2/23/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "NSInvocation+ObjectGetter.h"

@implementation NSInvocation (ObjectGetter)

- (id)objectArgumentAtIndex:(NSInteger)idx {
    __unsafe_unretained id tmp;
    // the first two arguments are `self` and `_cmd`
    [self getArgument:&tmp atIndex:(idx + 2)];
    id object = tmp;
    return object;
}

@end
