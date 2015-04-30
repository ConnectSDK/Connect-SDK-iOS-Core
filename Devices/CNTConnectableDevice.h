//
//  CNTConnectableDevice.h
//  Connect SDK
//
//  Created by Jeremy White on 12/9/13.
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
#import "CNTServiceDescription.h"
#import "CNTDeviceService.h"
#import "CNTConnectableDeviceDelegate.h"
#import "CNTDeviceServiceDelegate.h"
#import "CNTJSONObjectCoding.h"

#import "CNTLauncher.h"
#import "CNTVolumeControl.h"
#import "CNTTVControl.h"
#import "CNTMediaControl.h"
#import "CNTExternalInputControl.h"
#import "CNTToastControl.h"
#import "CNTTextInputControl.h"
#import "CNTMediaPlayer.h"
#import "CNTWebAppLauncher.h"
#import "CNTKeyControl.h"
#import "CNTMouseControl.h"
#import "CNTPowerControl.h"

/*!
 * ###Overview
 * CNTConnectableDevice serves as a normalization layer between your app and each of the device's services. It consolidates a lot of key data about the physical device and provides access to underlying functionality.
 *
 * ###In Depth
 * CNTConnectableDevice consolidates some key information about the physical device, including model name, friendly name, ip address, connected CNTDeviceService names, etc. In some cases, it is not possible to accurately select which CNTDeviceService has the best friendly name, model name, etc. In these cases, the values of these properties are dependent upon the order of CNTDeviceService discovery.
 *
 * To be informed of any ready/pairing/disconnect messages from each of the CNTDeviceService, you must set a delegate.
 *
 * CNTConnectableDevice exposes capabilities that exist in the underlying DeviceServices such as TV Control, Media Player, Media Control, Volume Control, etc. These capabilities, when accessed through the CNTConnectableDevice, will be automatically chosen from the most suitable CNTDeviceService by using that CNTDeviceService's CNTCapabilityPriorityLevel.
 */
@interface CNTConnectableDevice : NSObject <CNTDeviceServiceDelegate, CNTJSONObjectCoding>

// @cond INTERNAL
+ (instancetype) connectableDeviceWithDescription:(CNTServiceDescription *)description;
@property (nonatomic, strong) CNTServiceDescription *serviceDescription;
// @endcond

/*!
 * Delegate which should receive messages on certain events.
 */
@property (nonatomic, weak) id<CNTConnectableDeviceDelegate> delegate;

#pragma mark - General info

/*! Universally unique ID of this particular CNTConnectableDevice object, persists between sessions in CNTConnectableDeviceStore for connected devices  */
@property (nonatomic, readonly) NSString *id;

/*! Current IP address of the CNTConnectableDevice. */
@property (nonatomic, readonly) NSString *address;

/*! An estimate of the CNTConnectableDevice's current friendly name. */
@property (nonatomic, readonly) NSString *friendlyName;

/*! An estimate of the CNTConnectableDevice's current model name. */
@property (nonatomic, readonly) NSString *modelName;

/*! An estimate of the CNTConnectableDevice's current model number. */
@property (nonatomic, readonly) NSString *modelNumber;

/*! Last IP address this CNTConnectableDevice was discovered at. */
@property (nonatomic, copy) NSString *lastKnownIPAddress;

/*! Name of the last wireless network this CNTConnectableDevice was discovered on. */
@property (nonatomic, copy) NSString *lastSeenOnWifi;

/*! Last time (in seconds from 1970) that this CNTConnectableDevice was connected to. */
@property (nonatomic) double lastConnected;

/*! Last time (in seconds from 1970) that this CNTConnectableDevice was detected. */
@property (nonatomic) double lastDetection;

// @cond INTERNAL
- (NSString *) connectedServiceNames;
// @endcond

#pragma mark - Connection

/*!
 * Enumerates through all DeviceServices and attempts to connect to each of them. When all of a CNTConnectableDevice's DeviceServices are ready to receive commands, the CNTConnectableDevice will send a connectableDeviceReady: message to its delegate.
 *
 * It is always necessary to call connect on a CNTConnectableDevice, even if it contains no connectable DeviceServices.
 */
- (void) connect;

/*! Enumerates through all DeviceServices and attempts to disconnect from each of them. */
- (void) disconnect;

/*! Whether the device has any DeviceServices that require an active connection (websocket, HTTP registration, etc) */
@property (nonatomic, readonly) BOOL isConnectable;

/*! Whether all the DeviceServices are connected. */
@property (nonatomic, readonly) BOOL connected;

#pragma mark - Service management

/*! Array of all currently discovered DeviceServices this CNTConnectableDevice has associated with it. */
@property (nonatomic, readonly) NSArray *services;

/*! Whether the CNTConnectableDevice has any running DeviceServices associated with it. */
@property (nonatomic, readonly) BOOL hasServices;

/*!
 * Adds a CNTDeviceService to the CNTConnectableDevice instance. Only one instance of each CNTDeviceService type (webOS, Netcast, etc) may be attached to a single CNTConnectableDevice instance. If a device contains your service type already, your service will not be added.
 *
 * @param service CNTDeviceService to be added to the CNTConnectableDevice
 */
- (void) addService:(CNTDeviceService *)service;

/*!
 * Removes a CNTDeviceService from the CNTConnectableDevice instance. serviceId is used as the identifier because only one instance of each CNTDeviceService type may be attached to a single CNTConnectableDevice instance.
 *
 * @param serviceId Id of the CNTDeviceService to be removed from the CNTConnectableDevice
 */
- (void) removeServiceWithId:(NSString *)serviceId;

/*!
 * Obtains a service from the device with the provided serviceId
 *
 * @param serviceId Service ID of the targeted CNTDeviceService (webOS, Netcast, DLNA, etc)
 * @return CNTDeviceService with the specified serviceId or nil, if none exists
 */
- (CNTDeviceService *)serviceWithName:(NSString *)serviceId;

#pragma mark - Capabilities

#pragma mark Info

/*! A combined list of all capabilities that are supported among the detected DeviceServices. */
@property (nonatomic, readonly) NSArray *capabilities;

/*!
 * Test to see if the capabilities array contains a given capability. See the individual Capability classes for acceptable capability values.
 *
 * It is possible to append a wildcard search term `.Any` to the end of the search term. This method will return true for capabilities that match the term up to the wildcard.
 *
 * Example: `CNTLauncher.App.Any`
 *
 * @param capability Capability to test against
 */
- (BOOL) hasCapability:(NSString *)capability;

/*!
 * Test to see if the capabilities array contains a given set of capabilities. See the individual Capability classes for acceptable capability values.
 *
 * See hasCapability: for a description of the wildcard feature provided by this method.
 *
 * @param capabilities Array of capabilities to test against
 */
- (BOOL) hasCapabilities:(NSArray *)capabilities;

/*!
 * Test to see if the capabilities array contains at least one capability in a given set of capabilities. See the individual Capability classes for acceptable capability values.
 *
 * See hasCapability: for a description of the wildcard feature provided by this method.
 *
 * @param capabilities Array of capabilities to test against
 */
- (BOOL) hasAnyCapability:(NSArray *)capabilities;

/*!
 * Set the type of pairing for the CNTConnectableDevice services. By default the value will be CNTDeviceServicePairingTypeNone
 *
 *  For WebOSTV's If pairingType is set to CNTDeviceServicePairingTypeFirstScreen(default), the device will prompt the user to pair when connecting to the CNTConnectableDevice.
 *
 * If pairingType is set to CNTDeviceServicePairingTypePinCode, the device will prompt the user to enter a pin to pair when connecting to the CNTConnectableDevice.
 *
 * @param pairingType value to be set for the device service from CNTDeviceServicePairingType
 */
- (void)setPairingType:(CNTDeviceServicePairingType)pairingType;

#pragma mark Accessors

- (id<CNTLauncher>) launcher; /*! Accessor for highest priority CNTLauncher object */
- (id<CNTExternalInputControl>) externalInputControl; /*! Accessor for highest priority CNTExternalInputControl object */
- (id<CNTMediaPlayer>) mediaPlayer; /*! Accessor for highest priority CNTMediaPlayer object */
- (id<CNTMediaControl>) mediaControl; /*! Accessor for highest priority CNTMediaControl object */
- (id<CNTVolumeControl>)volumeControl; /*! Accessor for highest priority CNTVolumeControl object */
- (id<CNTTVControl>)tvControl; /*! Accessor for highest priority CNTTVControl object */
- (id<CNTKeyControl>) keyControl; /*! Accessor for highest priority CNTKeyControl object */
- (id<CNTTextInputControl>) textInputControl; /*! Accessor for highest priority CNTTextInputControl object */
- (id<CNTMouseControl>)mouseControl; /*! Accessor for highest priority CNTMouseControl object */
- (id<CNTPowerControl>)powerControl; /*! Accessor for highest priority CNTPowerControl object */
- (id<CNTToastControl>) toastControl; /*! Accessor for highest priority CNTToastControl object */
- (id<CNTWebAppLauncher>) webAppLauncher; /*! Accessor for highest priority CNTWebAppLauncher object */

@end
