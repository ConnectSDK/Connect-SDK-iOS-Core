//
//  CNTDiscoveryProviderDelegate.h
//  Connect SDK
//
//  Created by Andrew Longstaff on 9/6/13.
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

@class CNTDiscoveryProvider;
@class CNTServiceDescription;

/*!
 * The CNTDiscoveryProviderDelegate is mechanism for passing service information to the CNTDiscoveryManager. You likely will not be using the CNTDiscoveryProviderDelegate class directly, as CNTDiscoveryManager acts as a delegate to all of the DiscoveryProviders.
 */
@protocol CNTDiscoveryProviderDelegate <NSObject>

/*!
 * This method is called when the CNTDiscoveryProvider discovers a service that matches one of its CNTDeviceService filters. The CNTServiceDescription is created and passed to the delegate (which should be the CNTDiscoveryManager). The CNTServiceDescription is used to create a CNTDeviceService, which is then attached to a CNTConnectableDevice object.
 *
 * @param provider CNTDiscoveryProvider that found the service
 * @param description CNTServiceDescription of the service that was found
 */
- (void) discoveryProvider:(CNTDiscoveryProvider *)provider didFindService:(CNTServiceDescription *)description;

/*!
 * This method is called when the CNTDiscoveryProvider's internal mechanism loses reference to a service that matches one of its CNTDeviceService filters.
 *
 * @param provider CNTDiscoveryProvider that lost the service
 * @param description CNTServiceDescription of the service that was lost
 */
- (void) discoveryProvider:(CNTDiscoveryProvider *)provider didLoseService:(CNTServiceDescription *)description;

/*!
 * This method is called on any error/failure within the CNTDiscoveryProvider.
 *
 * @param provider CNTDiscoveryProvider that failed
 * @param error NSError providing a information about the failure
 */
- (void) discoveryProvider:(CNTDiscoveryProvider *)provider didFailWithError:(NSError*)error;

@end
