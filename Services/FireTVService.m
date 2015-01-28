//
//  FireTVService.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/26/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "FireTVService.h"

NSString *const kConnectSDKFireTVServiceId = @"FireTV";

@implementation FireTVService

+ (DiscoveryFilter *) discoveryParameters
{
    return [DiscoveryFilter filterWithServiceId:kConnectSDKFireTVServiceId
                                         filter:@"urn:dial-multiscreen-org:service:dial:1"
                               requiredServices:nil
                       andModelNameMatcherBlock:^BOOL(NSString *modelName) {
                           return (NSNotFound != [modelName rangeOfString:@"FireTV"].location);
                       }];
}

@end
