//
//  NSString+Common.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 3/16/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Common)

/// Returns itself if not `nil`, or an empty string otherwise.
- (NSString *)orEmpty;

@end
