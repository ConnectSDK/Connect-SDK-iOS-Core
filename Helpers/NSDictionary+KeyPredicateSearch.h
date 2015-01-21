//
//  NSDictionary+KeyPredicateSearch.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/13/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Extends the NSDictionary interface to be able to get objects by keys
 * matching a predicate.
 */
@interface NSDictionary (KeyPredicateSearch)

/// Returns an object for a key which name matches the given predicate.
/// @warning There must be at most one matching key in the dictionary.
- (id)objectForKeyWithPredicate:(NSPredicate *)predicate;

/// Returns an object for a key which name ends with the given string.
/// @warning There must be at most one matching key in the dictionary.
- (id)objectForKeyEndingWithString:(NSString *)string;

@end
