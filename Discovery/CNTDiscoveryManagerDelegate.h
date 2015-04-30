//
//  CNTDiscoveryManagerDelegate.h
//  Connect SDK
//
//  Created by Jeremy White on 12/4/13.
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

@class CNTDiscoveryManager;
@class CNTConnectableDevice;


/*!
 * ###Overview
 * The CNTDiscoveryManagerDelegate will receive events on the addition/removal/update of CNTConnectableDevice objects.
 *
 * ###In Depth
 * It is important to note that, unless you are implementing your own device picker, this delegate is not needed in your code. Connect SDK's CNTDevicePicker internally acts a separate delegate to the CNTDiscoveryManager and handles all of the same method calls.
 */
@protocol CNTDiscoveryManagerDelegate <NSObject>

@optional
/*!
 * This method will be fired upon the first discovery of one of a CNTConnectableDevice's DeviceServices.
 *
 * @param manager CNTDiscoveryManager that found device
 * @param device CNTConnectableDevice that was found
 */
- (void) discoveryManager:(CNTDiscoveryManager *)manager didFindDevice:(CNTConnectableDevice *)device;

/*!
 * This method is called when connections to all of a CNTConnectableDevice's DeviceServices are lost. This will usually happen when a device is powered off or loses internet connectivity.
 *
 * @param manager CNTDiscoveryManager that lost device
 * @param device CNTConnectableDevice that was lost
 */
- (void) discoveryManager:(CNTDiscoveryManager *)manager didLoseDevice:(CNTConnectableDevice *)device;

/*!
 * This method is called when a CNTConnectableDevice gains or loses a CNTDeviceService in discovery.
 *
 * @param manager CNTDiscoveryManager that updated device
 * @param device CNTConnectableDevice that was updated
 */
- (void) discoveryManager:(CNTDiscoveryManager *)manager didUpdateDevice:(CNTConnectableDevice *)device;

/*!
 * In the event of an error in the discovery phase, this method will be called.
 *
 * @param manager CNTDiscoveryManager that experienced the error
 * @param error NSError with a description of the failure
 */
- (void) discoveryManager:(CNTDiscoveryManager *)manager didFailWithError:(NSError*)error;

@end
