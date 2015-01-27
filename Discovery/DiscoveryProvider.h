//
//  DiscoveryProvider.h
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
//  Copyright (c) 2014 LG Electronics.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import "DiscoveryFilter.h"
#import "DiscoveryProviderDelegate.h"

/*!
 * ###Overview
 * From a high-level perspective, DiscoveryProvider completely abstracts the functionality of discovering services of a particular protocol (SSDP, Cast, etc). The DiscoveryProvider will pass service information to the DiscoveryManager, which will then create a DeviceService object and attach it to a ConnectableDevice object.
 *
 * ###In Depth
 * DiscoveryProvider is an abstract class that is meant to be extended. You shouldn't ever use DiscoveryProvider directly, unless extending it to provide support for another discovery protocol.
 *
 * By default, DiscoveryManager will set itself as a DiscoveryProvider's delegate. You should not change the delegate as it could cause unexpected inconsistencies within the discovery process.
 *
 * See CastDiscoveryProvider and SSDPDiscoveryProvider for implementations.
 */
@interface DiscoveryProvider : NSObject

/*! DiscoveryProviderDelegate, which should be the DiscoveryManager */
@property (nonatomic, weak) id<DiscoveryProviderDelegate> delegate;

/*! Whether or not the DiscoveryProvider is running */
@property (nonatomic) BOOL isRunning;

/*!
 * Whether or not the DiscoveryProvider has any services it is supposed to be searching for. If YES, then the DiscoveryProvider will be stopped and de-referenced by the DiscoveryManager.
 */
@property (nonatomic, readonly) BOOL isEmpty;

/*!
 * Adds a device filter for a particular DeviceService.
 *
 * @param filter Filter to be used for discovering a particular DeviceService
 */
- (void) addDeviceFilter:(DiscoveryFilter *)filter;

/*!
 * Removes a device filter for a particular DeviceService. If the DiscoveryProvider has no other devices to be searching for, the DiscoveryProvider will be stopped and de-referenced.
 *
 * @param filter Filter to be used for discovering a particular DeviceService
 */
- (void) removeDeviceFilter:(DiscoveryFilter *)filter;

/*!
 * Starts the DiscoveryProvider.
 */
- (void) startDiscovery;

/*!
 * Stops the DiscoveryProvider.
 */
- (void) stopDiscovery;

@end
