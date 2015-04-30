//
//  CNTDiscoveryProvider.h
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
#import "CNTDiscoveryProviderDelegate.h"


/*!
 * ###Overview
 * From a high-level perspective, CNTDiscoveryProvider completely abstracts the functionality of discovering services of a particular protocol (SSDP, Cast, etc). The CNTDiscoveryProvider will pass service information to the CNTDiscoveryManager, which will then create a CNTDeviceService object and attach it to a CNTConnectableDevice object.
 *
 * ###In Depth
 * CNTDiscoveryProvider is an abstract class that is meant to be extended. You shouldn't ever use CNTDiscoveryProvider directly, unless extending it to provide support for another discovery protocol.
 *
 * By default, CNTDiscoveryManager will set itself as a CNTDiscoveryProvider's delegate. You should not change the delegate as it could cause unexpected inconsistencies within the discovery process.
 *
 * See CNTCastDiscoveryProvider and CNTSSDPDiscoveryProvider for implementations.
 */
@interface CNTDiscoveryProvider : NSObject

/*! CNTDiscoveryProviderDelegate, which should be the CNTDiscoveryManager */
@property (nonatomic, weak) id<CNTDiscoveryProviderDelegate> delegate;

/*! Whether or not the CNTDiscoveryProvider is running */
@property (nonatomic) BOOL isRunning;

/*!
 * Whether or not the CNTDiscoveryProvider has any services it is supposed to be searching for. If YES, then the CNTDiscoveryProvider will be stopped and de-referenced by the CNTDiscoveryManager.
 */
@property (nonatomic, readonly) BOOL isEmpty;

/*!
 * Adds a device filter for a particular CNTDeviceService.
 *
 * @param parameters Parameters to be used for discovering a particular CNTDeviceService
 */
- (void) addDeviceFilter:(NSDictionary *)parameters;

/*!
 * Removes a device filter for a particular CNTDeviceService. If the CNTDiscoveryProvider has no other devices to be searching for, the CNTDiscoveryProvider will be stopped and de-referenced.
 *
 * @param parameters Parameters to be used for discovering a particular CNTDeviceService
 */
- (void) removeDeviceFilter:(NSDictionary *)parameters;

/*!
 * Starts the CNTDiscoveryProvider.
 */
- (void) startDiscovery;

/*!
 * Stops the CNTDiscoveryProvider.
 */
- (void) stopDiscovery;

@end
