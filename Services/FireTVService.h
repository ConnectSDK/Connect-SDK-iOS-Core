//
//  FireTVService.h
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/26/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "DeviceService.h"
#import "WebAppLauncher.h"

/// Service ID for Fire TV devices.
extern NSString *const kConnectSDKFireTVServiceId;

/**
 * This service requires DIALService.
 */
@interface FireTVService : DeviceService <WebAppLauncher>

@end
