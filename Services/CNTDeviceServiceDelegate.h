//
//  CNTDeviceServiceDelegate.h
//  Connect SDK
//
//  Created by Jeremy White on 12/23/13.
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

/*!
 * Type of pairing that is required by a particular CNTDeviceService. This type will be passed along with the CNTDeviceServiceDelegate deviceService:pairingRequiredOfType:withData: message.
 */
typedef enum {
    /*! CNTDeviceService does not require pairing */
    CNTDeviceServicePairingTypeNone = 0,

    /*! CNTDeviceService requires user interaction on the first screen (ex. pairing alert) */
    CNTDeviceServicePairingTypeFirstScreen,

    /*! First screen is displaying a pairing pin code that can be sent through the CNTDeviceService */
    CNTDeviceServicePairingTypePinCode,

    /*! CNTDeviceService can pair with multiple pairing types (ex. first screen OR pin) */
    CNTDeviceServicePairingTypeMixed,

    /*! CNTDeviceService requires AirPlay mirroring to be enabled to connect */
    CNTDeviceServicePairingTypeAirPlayMirroring,

    /*! CNTDeviceService pairing type is unknown */
    CNTDeviceServicePairingTypeUnknown
} CNTDeviceServicePairingType;

@class CNTDeviceService;


/*!
 * CNTDeviceServiceDelegate allows your app to respond to each step of the connection and pairing processes, if needed. By default, a CNTDeviceService's CNTConnectableDevice is set as the delegate. Changing a CNTDeviceService's delegate will break the normal operation of Connect SDK and is discouraged. CNTConnectableDeviceDelegate provides proxy methods for all of the methods listed here.
 */
@protocol CNTDeviceServiceDelegate <NSObject>

@optional

/*!
 * If the CNTDeviceService requires an active connection (websocket, pairing, etc) this method will be called.
 *
 * @param service CNTDeviceService that requires connection
 */
- (void) deviceServiceConnectionRequired:(CNTDeviceService *)service;

/*!
 * After the connection has been successfully established, and after pairing (if applicable), this method will be called.
 *
 * @param service CNTDeviceService that was successfully connected
 */
- (void) deviceServiceConnectionSuccess:(CNTDeviceService *)service;

/*!
 * There are situations in which a CNTDeviceService will update the capabilities it supports and propagate these changes to the CNTDeviceService. Such situations include:
 * - on discovery, CNTDIALService will reach out to detect if certain apps are installed
 * - on discovery, certain DeviceServices need to reach out for version & region information
 *
 * For more information on this particular method, see CNTConnectableDeviceDelegate's connectableDevice:capabilitiesAdded:removed: method.
 *
 * @param service CNTDeviceService that has experienced a change in capabilities
 * @param added NSArray of capabilities that are new to the CNTDeviceService
 * @param removed NSArray of capabilities that the CNTDeviceService has lost
 */
- (void) deviceService:(CNTDeviceService *)service capabilitiesAdded:(NSArray *)added removed:(NSArray *)removed;

/*!
 * This method will be called on any disconnection. If error is nil, then the connection was clean and likely triggered by the responsible CNTDiscoveryProvider or by the user.
 *
 * @param service CNTDeviceService that disconnected
 * @param error NSError with a description of any errors causing the disconnect. If this value is nil, then the disconnect was clean/expected.
 */
- (void) deviceService:(CNTDeviceService *)service disconnectedWithError:(NSError*)error;

/*!
 * Will be called if the CNTDeviceService fails to establish a connection.
 *
 * @param service CNTDeviceService which has failed to connect
 * @param error NSError with a description of the failure
 */
- (void) deviceService:(CNTDeviceService *)service didFailConnectWithError:(NSError*)error;

/*!
 * If the CNTDeviceService requires pairing, valuable data will be passed to the delegate via this method.
 *
 * @param service CNTDeviceService that requires pairing
 * @param pairingType CNTDeviceServicePairingType that the CNTDeviceService requires
 * @param pairingData Any object/data that might be required for the pairing process, will usually be nil
 */
- (void) deviceService:(CNTDeviceService *)service pairingRequiredOfType:(CNTDeviceServicePairingType)pairingType withData:(id)pairingData;

/*!
 * This method will be called upon pairing success. On pairing success, a connection to the CNTDeviceService will be attempted.
 *
 * @property service CNTDeviceService that has successfully completed pairing
 */
- (void) deviceServicePairingSuccess:(CNTDeviceService *)service;

/*!
 * If there is any error in pairing, this method will be called.
 *
 * @param service CNTDeviceService that has failed to complete pairing
 * @param error NSError with a description of the failure
 */
- (void) deviceService:(CNTDeviceService *)service pairingFailedWithError:(NSError*)error;

@end
