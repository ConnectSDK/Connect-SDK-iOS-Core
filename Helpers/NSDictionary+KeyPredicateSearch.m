//
//  NSDictionary+KeyPredicateSearch.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/13/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "NSDictionary+KeyPredicateSearch.h"

@implementation NSDictionary (KeyPredicateSearch)

- (id)objectForKeyWithPredicate:(NSPredicate *)predicate {
    if (!predicate) {
        return nil;
    }

    NSArray *predicateKeys = [self.allKeys filteredArrayUsingPredicate:predicate];
    NSAssert(predicateKeys.count <= 1, @"There are %ld object for predicate %@",
             (unsigned long)predicateKeys.count, predicate);
    return self[predicateKeys.firstObject];
}

- (id)objectForKeyEndingWithString:(NSString *)string {
    return [self objectForKeyWithPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH %@", string]];
}

@end
