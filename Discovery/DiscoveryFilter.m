//
//  DiscoveryFilter.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/27/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "DiscoveryFilter.h"

@implementation DiscoveryFilter

#pragma mark - Init

- (instancetype)initWithServiceId:(NSString *)serviceId
                           filter:(NSString *)filter
              andRequiredServices:(NSArray *)requiredServices {
    if (self = [super init]) {
        _serviceId = [serviceId copy];
        _filter = [filter copy];
        _requiredServices = [requiredServices copy];
    }
    return self;
}

- (instancetype)initWithServiceId:(NSString *)serviceId
                        andFilter:(NSString *)filter {
    return [self initWithServiceId:serviceId
                            filter:filter
               andRequiredServices:nil];
}

+ (instancetype)filterWithServiceId:(NSString *)serviceId
                             filter:(NSString *)filter
                andRequiredServices:(NSArray *)requiredServices {
    return [[[self class] alloc] initWithServiceId:serviceId
                                            filter:filter
                               andRequiredServices:requiredServices];
}

+ (instancetype)filterWithServiceId:(NSString *)serviceId
                          andFilter:(NSString *)filter {
    return [[self class] filterWithServiceId:serviceId
                                      filter:filter
                         andRequiredServices:nil];
}

@end
