//
//  DiscoveryFilter.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/27/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Stores the discovery filter setup for a particular service.
 */
@interface DiscoveryFilter : NSObject

/// The unique identifier of a service.
@property (nonatomic, copy, readonly) NSString *serviceId;

/// The filter string used for discovery (SSDP filter or Zeroconf service type).
@property (nonatomic, copy, readonly) NSString *filter;

/// An array of device services (@c NSString objects) that must be available for
/// the particular ConnectSDK service.
@property (nonatomic, copy, readonly) NSArray *requiredServices;


/// Designated initializer.
- (instancetype)initWithServiceId:(NSString *)serviceId
                           filter:(NSString *)filter
              andRequiredServices:(NSArray *)requiredServices;

- (instancetype)initWithServiceId:(NSString *)serviceId
                        andFilter:(NSString *)filter;

+ (instancetype)filterWithServiceId:(NSString *)serviceId
                             filter:(NSString *)filter
                andRequiredServices:(NSArray *)requiredServices;

+ (instancetype)filterWithServiceId:(NSString *)serviceId
                          andFilter:(NSString *)filter;

@end
