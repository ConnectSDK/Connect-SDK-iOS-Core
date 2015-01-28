//
//  DiscoveryFilter.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/27/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>

/// Block type that allows to match the model name for the given service.
typedef BOOL(^ModelNameMatcherBlock)(NSString *modelName);

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

/// A block that allows to match the model name for the given service.
@property (nonatomic, copy, readonly) ModelNameMatcherBlock modelNameMatcherBlock;


/// Designated initializer.
- (instancetype)initWithServiceId:(NSString *)serviceId
                           filter:(NSString *)filter
                 requiredServices:(NSArray *)requiredServices
         andModelNameMatcherBlock:(ModelNameMatcherBlock)modelNameMatcherBlock;

- (instancetype)initWithServiceId:(NSString *)serviceId
                           filter:(NSString *)filter
              andRequiredServices:(NSArray *)requiredServices;

- (instancetype)initWithServiceId:(NSString *)serviceId
                        andFilter:(NSString *)filter;


+ (instancetype)filterWithServiceId:(NSString *)serviceId
                             filter:(NSString *)filter
                   requiredServices:(NSArray *)requiredServices
           andModelNameMatcherBlock:(ModelNameMatcherBlock)modelNameMatcherBlock;

+ (instancetype)filterWithServiceId:(NSString *)serviceId
                             filter:(NSString *)filter
                andRequiredServices:(NSArray *)requiredServices;

+ (instancetype)filterWithServiceId:(NSString *)serviceId
                          andFilter:(NSString *)filter;

@end
