//
//  CNTDiscoveryManager.h
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
#import "CNTDiscoveryManagerDelegate.h"
#import "CNTDevicePicker.h"
#import "CNTConnectableDeviceStore.h"

/*!
 * ###Overview
 *
 * At the heart of Connect SDK is CNTDiscoveryManager, a multi-protocol service discovery engine with a pluggable architecture. Much of your initial experience with Connect SDK will be with the CNTDiscoveryManager class, as it consolidates discovered service information into CNTConnectableDevice objects.
 *
 * ###In depth
 * CNTDiscoveryManager supports discovering services of differing protocols by using DiscoveryProviders. Many services are discoverable over [SSDP][0] and are registered to be discovered with the CNTSSDPDiscoveryProvider class.
 *
 * As services are discovered on the network, the DiscoveryProviders will notify CNTDiscoveryManager. CNTDiscoveryManager is capable of attributing multiple services, if applicable, to a single CNTConnectableDevice instance. Thus, it is possible to have a mixed-mode CNTConnectableDevice object that is theoretically capable of more functionality than a single service can provide.
 *
 * CNTDiscoveryManager keeps a running list of all discovered devices and maintains a filtered list of devices that have satisfied any of your CapabilityFilters. This filtered list is used by the CNTDevicePicker when presenting the user with a list of devices.
 *
 * Only one instance of the CNTDiscoveryManager should be in memory at a time. To assist with this, CNTDiscoveryManager has singleton accessors at sharedManager and sharedManagerWithDeviceStore:.
 *
 * Example:
 *
 * @capability kCNTMediaControlPlay
 *
 @code
   CNTDiscoveryManager *discoveryManager = [CNTDiscoveryManager sharedManager];
   discoveryManager.delegate = self; // set delegate to listen for discovery events
   [discoveryManager startDiscovery];
 @endcode
 *
 * [0]: http://tools.ietf.org/html/draft-cai-ssdp-v1-03
 */
@interface CNTDiscoveryManager : NSObject <CNTConnectableDeviceDelegate>

/*!
 * Delegate which should receive discovery updates. It is not necessary to set this delegate property unless you are implementing your own device picker. Connect SDK provides a default CNTDevicePicker which acts as a CNTDiscoveryManagerDelegate, and should work for most cases.
 *
 * If you have provided a capabilityFilters array, the delegate will only receive update messages for ConnectableDevices which satisfy at least one of the CapabilityFilters. If no capabilityFilters array is provided, the delegate will receive update messages for all CNTConnectableDevice objects that are discovered.
 */
@property (nonatomic, weak) id<CNTDiscoveryManagerDelegate> delegate;

/*!
 * Singleton accessor for CNTDiscoveryManager. This method calls sharedManagerWithDeviceStore: and passes an instance of CNTDefaultConnectableDeviceStore.
 */
+ (instancetype) sharedManager;

/*!
 * Singleton accessor for CNTDiscoveryManager, will initialize singleton with reference to a custom CNTConnectableDeviceStore object.
 *
 * @param deviceStore (optional) An object which implements the CNTConnectableDeviceStore protocol to be used for save/load of device information. You may provide nil to completely disable the device store capabilities of the SDK.
 */
+ (instancetype) sharedManagerWithDeviceStore:(id<CNTConnectableDeviceStore>)deviceStore;

/*!
 * Filtered list of discovered ConnectableDevices, limited to devices that match at least one of the CapabilityFilters in the capabilityFilters array. Each CNTConnectableDevice object is keyed against its current IP address.
 */
- (NSDictionary *) compatibleDevices;

/*!
 * List of all devices discovered by CNTDiscoveryManager. Each CNTConnectableDevice object is keyed against its current IP address.
 */
- (NSDictionary *) allDevices;

#pragma mark - Configuration & Device Registration

// @cond INTERNAL

/*
 * Registers a commonly-used set of DeviceServices with CNTDiscoveryManager. This method will be called on first call of startDiscovery if no DeviceServices have been registered.
 *
 * - CNTCastDiscoveryProvider
 *   + CNTCastService
 * - CNTSSDPDiscoveryProvider
 *   + CNTDIALService
 *   + CNTDLNAService (limited to LG TVs, currently)
 *   + CNTNetcastTVService
 *   + CNTRokuService
 *   + CNTWebOSTVService
 */
- (void) registerDefaultServices;

/*
 * Registers a CNTDeviceService with CNTDiscoveryManager and tells it which CNTDiscoveryProvider to use to find it. Each CNTDeviceService has an NSDictionary of discovery parameters that its CNTDiscoveryProvider will use to find it.
 *
 * @param deviceClass Class for object that should be instantiated when CNTDeviceService is found
 * @param discoveryClass Class for object that should discover this CNTDeviceService. If a CNTDiscoveryProvider of this class already exists, then the existing CNTDiscoveryProvider will be used.
 */
- (void) registerDeviceService:(Class)deviceClass withDiscovery:(Class)discoveryClass;

/*
 * Unregisters a CNTDeviceService with CNTDiscoveryManager. If no other DeviceServices are set to being discovered with the associated CNTDiscoveryProvider, then that CNTDiscoveryProvider instance will be stopped and shut down.
 *
 * @param deviceClass Class for CNTDeviceService that should no longer be discovered
 * @param discoveryClass Class for CNTDiscoveryProvider that is discovering DeviceServices of deviceClass type
 */
- (void) unregisterDeviceService:(Class)deviceClass withDiscovery:(Class)discoveryClass;

// @endcond

/*!
 * A CNTConnectableDevice will be displayed in the CNTDevicePicker and compatibleDevices array if it matches any of the CNTCapabilityFilter objects in this array.
 */
@property (nonatomic, strong) NSArray *capabilityFilters;

/*!
 * The pairingLevel property determines whether capabilities that require pairing (such as entering a PIN) will be available.
 *
 * If pairingLevel is set to CNTDeviceServicePairingLevelOn, ConnectableDevices that require pairing will prompt the user to pair when connecting to the CNTConnectableDevice.
 *
 * If pairingLevel is set to CNTDeviceServicePairingLevelOff (the default), connecting to the device will avoid requiring pairing if possible but some capabilities may not be available.
 */
@property (nonatomic) CNTDeviceServicePairingLevel pairingLevel;

#pragma mark - Control

/*!
 * Start scanning for devices on the local network.
 */
- (void) startDiscovery;

/*!
 * Stop scanning for devices.
 *
 * This method will be called when your app enters a background state. When your app resumes, startDiscovery will be called.
 */
- (void) stopDiscovery;

#pragma mark - Device Picker

/*!
 * Get a CNTDevicePicker to show compatible ConnectableDevices that have been found by CNTDiscoveryManager.
 *
 * @return CNTDevicePicker CNTDevicePicker singleton for use in picking devices
 */
- (CNTDevicePicker *) devicePicker;

#pragma mark - Device Store

/*!
 * CNTConnectableDeviceStore object which loads & stores references to all discovered devices. Pairing codes/keys, SSL certificates, recent access times, etc are kept in the device store.
 *
 * CNTConnectableDeviceStore is a protocol which may be implemented as needed. A default implementation, CNTDefaultConnectableDeviceStore, exists for convenience and will be used if no other device store is provided.
 *
 * In order to satisfy user privacy concerns, you should provide a UI element in your app which exposes the CNTConnectableDeviceStore removeAll method.
 *
 * To disable the CNTConnectableDeviceStore capabilities of Connect SDK, set this value to nil. This may be done at the time of instantiation with `[CNTDiscoveryManager sharedManagerWithDeviceStore:nil]`.
 */
@property (nonatomic, strong) id<CNTConnectableDeviceStore> deviceStore;

/*!
 * Whether pairing state will be automatically loaded/saved in the deviceStore. This property is not available for direct modification. To disable the device store,
 */
@property (nonatomic, readonly) BOOL useDeviceStore;

// @cond INTERNAL

@property (nonatomic, readonly) NSDictionary *deviceClasses;

@property (nonatomic, readonly) NSArray *discoveryProviders;

// @endcond

@end
