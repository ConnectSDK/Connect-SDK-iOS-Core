//
//  CNTConnectableDeviceDelegate.h
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

@class CNTConnectableDevice;
@class CNTDeviceService;

/*!
 * CNTConnectableDeviceDelegate allows for a class to receive messages about CNTConnectableDevice connection, disconnect, and update events.
 *
 * It also serves as a delegate proxy for message handling when connecting and pairing with each of a CNTConnectableDevice's DeviceServices. Each of the CNTDeviceService proxy methods are optional and would only be useful in a few use cases.
 * - providing your own UI for the pairing process.
 * - interacting directly and exclusively with a single type of CNTDeviceService
 */
@protocol CNTConnectableDeviceDelegate <NSObject>

/*!
 * A CNTConnectableDevice sends out a ready message when all of its connectable DeviceServices have been connected and are ready to receive commands.
 *
 * @param device CNTConnectableDevice that is ready for commands.
 */
- (void) connectableDeviceReady:(CNTConnectableDevice *)device;

/*!
 * When all of a CNTConnectableDevice's DeviceServices have become disconnected, the disconnected message is sent.
 *
 * @param device CNTConnectableDevice that has been disconnected.
 */
- (void) connectableDeviceDisconnected:(CNTConnectableDevice *)device withError:(NSError *)error;

@optional

/*!
 * When a CNTConnectableDevice finds & loses DeviceServices, that CNTConnectableDevice will experience a change in its collective capabilities list. When such a change occurs, this message will be sent with arrays of capabilities that were added & removed.
 *
 * This message will allow you to decide when to stop/start interacting with a CNTConnectableDevice, based off of its supported capabilities.
 *
 * @param device CNTConnectableDevice that has experienced a change in capabilities
 * @param added NSArray of capabilities that are new to the CNTConnectableDevice
 * @param removed NSArray of capabilities that the CNTConnectableDevice has lost
 */
- (void) connectableDevice:(CNTConnectableDevice *)device capabilitiesAdded:(NSArray *)added removed:(NSArray *)removed;

/*!
 * This method is called when the connection to the CNTConnectableDevice has failed.
 *
 * @param device CNTConnectableDevice that has failed to connect
 * @param error NSError with a description of the failure
 */
- (void) connectableDevice:(CNTConnectableDevice *)device connectionFailedWithError:(NSError *)error;

#pragma mark - CNTDeviceService delegate proxy methods

/*!
 * CNTDeviceService delegate proxy method.
 *
 * This method is called when a CNTDeviceService requires an active connection. This will be the case for DeviceServices that send messages over websockets (webOS, etc) and DeviceServices that require pairing to send messages (Netcast, etc).
 *
 * @param device CNTConnectableDevice containing the CNTDeviceService
 * @param service CNTDeviceService which requires a connection
 */
- (void) connectableDeviceConnectionRequired:(CNTConnectableDevice *)device forService:(CNTDeviceService *)service;

/*!
 * CNTDeviceService delegate proxy method.
 *
 * This method is called when a CNTDeviceService has successfully connected.
 *
 * @param device CNTConnectableDevice containing the CNTDeviceService
 * @param service CNTDeviceService which has connected
 */
- (void) connectableDeviceConnectionSuccess:(CNTConnectableDevice *)device forService:(CNTDeviceService *)service;

/*!
 * CNTDeviceService delegate proxy method.
 *
 * This method is called when a CNTDeviceService becomes disconnected.
 *
 * @param device CNTConnectableDevice containing the CNTDeviceService
 * @param service CNTDeviceService which has disconnected
 * @param error NSError with a description of any errors causing the disconnect. If this value is nil, then the disconnect was clean/expected.
 */
- (void) connectableDevice:(CNTConnectableDevice *)device service:(CNTDeviceService *)service disconnectedWithError:(NSError*)error;

/*!
 * CNTDeviceService delegate proxy method.
 *
 * This method is called when a CNTDeviceService fails to connect.
 *
 * @param device CNTConnectableDevice containing the CNTDeviceService
 * @param service CNTDeviceService which has failed to connect
 * @param error NSError with a description of the failure
 */
- (void) connectableDevice:(CNTConnectableDevice *)device service:(CNTDeviceService *)service didFailConnectWithError:(NSError*)error;

/*!
 * CNTDeviceService delegate proxy method.
 *
 * This method is called when a CNTDeviceService tries to connect and finds out that it requires pairing information from the user.
 *
 * @param device CNTConnectableDevice containing the CNTDeviceService
 * @param service CNTDeviceService that requires pairing
 * @param pairingType CNTDeviceServicePairingType that the CNTDeviceService requires
 * @param pairingData Any data that might be required for the pairing process, will usually be nil
 */
- (void) connectableDevice:(CNTConnectableDevice *)device service:(CNTDeviceService *)service pairingRequiredOfType:(int)pairingType withData:(id)pairingData;

/*!
 * CNTDeviceService delegate proxy method.
 *
 * This method is called when a CNTDeviceService completes the pairing process.
 *
 * @param device CNTConnectableDevice containing the CNTDeviceService
 * @param service CNTDeviceService that has successfully completed pairing
 */
- (void) connectableDevicePairingSuccess:(CNTConnectableDevice *)device service:(CNTDeviceService *)service;

/*!
 * CNTDeviceService delegate proxy method.
 *
 * This method is called when a CNTDeviceService fails to complete the pairing process.
 *
 * @param device CNTConnectableDevice containing the CNTDeviceService
 * @param service CNTDeviceService that has failed to complete pairing
 * @param error NSError with a description of the failure
 */
- (void) connectableDevice:(CNTConnectableDevice *)device service:(CNTDeviceService *)service pairingFailedWithError:(NSError*)error;

@end
