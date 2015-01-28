//
//  DiscoveryFilter.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/27/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "DiscoveryFilter.h"

/*
 TODO: use the Builder pattern to construct the object instead of multiple
    initializers.
 TODO: use a dictionary propertyName:matcherBlock instead of adding
    modelDescriptionMatcherBlock (for NetcastTVService)?
 */

@implementation DiscoveryFilter

#pragma mark - Init

- (instancetype)initWithServiceId:(NSString *)serviceId
                           filter:(NSString *)filter
                 requiredServices:(NSArray *)requiredServices
         andModelNameMatcherBlock:(ModelNameMatcherBlock)modelNameMatcherBlock {
    if (self = [super init]) {
        _serviceId = [serviceId copy];
        _filter = [filter copy];
        _requiredServices = [requiredServices copy];
        _modelNameMatcherBlock = [modelNameMatcherBlock copy];
    }
    return self;
}

- (instancetype)initWithServiceId:(NSString *)serviceId
                           filter:(NSString *)filter
              andRequiredServices:(NSArray *)requiredServices {
    return [self initWithServiceId:serviceId
                            filter:filter
               andRequiredServices:requiredServices];
}

- (instancetype)initWithServiceId:(NSString *)serviceId
                        andFilter:(NSString *)filter {
    return [self initWithServiceId:serviceId
                            filter:filter
               andRequiredServices:nil];
}

+ (instancetype)filterWithServiceId:(NSString *)serviceId
                             filter:(NSString *)filter
                   requiredServices:(NSArray *)requiredServices
           andModelNameMatcherBlock:(ModelNameMatcherBlock)modelNameMatcherBlock {
    return [[[self class] alloc] initWithServiceId:serviceId
                                            filter:filter
                                  requiredServices:requiredServices
                          andModelNameMatcherBlock:modelNameMatcherBlock];
}

+ (instancetype)filterWithServiceId:(NSString *)serviceId
                             filter:(NSString *)filter
                andRequiredServices:(NSArray *)requiredServices {
    return [[self class] filterWithServiceId:serviceId
                                      filter:filter
                            requiredServices:requiredServices
                    andModelNameMatcherBlock:nil];
}

+ (instancetype)filterWithServiceId:(NSString *)serviceId
                          andFilter:(NSString *)filter {
    return [[self class] filterWithServiceId:serviceId
                                      filter:filter
                         andRequiredServices:nil];
}

#pragma mark -

- (NSString *)description {
    return [NSString stringWithFormat:@"DiscoveryFilter [serviceId=%@, filter=%@, requiredServices=%@]",
            self.serviceId, self.filter, self.requiredServices];
}

@end
