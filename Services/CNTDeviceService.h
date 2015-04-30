//
//  CNTDeviceService.h
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
#import "CNTServiceDescription.h"
#import "CNTServiceConfig.h"
#import "CNTConnectableDeviceDelegate.h"
#import "CNTDeviceServiceDelegate.h"
#import "CNTCapability.h"
#import "CNTLaunchSession.h"

/*!
 * Enumerated value for determining how a CNTDeviceService should handle pairing when attempting to connect.
 */
typedef enum {
    /*! DeviceServices will never try to pair with a device */
    CNTDeviceServicePairingLevelOff = 0,
    
    /*! DeviceServices will try to pair with a device, if needed */
    CNTDeviceServicePairingLevelOn
} CNTDeviceServicePairingLevel;

/*!
 * Enumerated value for determining how a CNTDeviceService should handle pairing when attempting to connect.
 */
typedef enum {
    /*! DeviceServices will never try to pair with a device */
    ConnectableDevicePairingLevelOff __attribute__((deprecated)) = CNTDeviceServicePairingLevelOff,
    
    /*! DeviceServices will try to pair with a device, if needed */
    ConnectableDevicePairingLevelOn __attribute__((deprecated)) = CNTDeviceServicePairingLevelOn
} ConnectableDevicePairingLevel;

/*!
 * ###Overview
 * From a high-level perspective, CNTDeviceService completely abstracts the functionality of a particular service/protocol (webOS TV, Netcast TV, Chromecast, Roku, DIAL, etc).
 *
 * ###In Depth
 * CNTDeviceService is an abstract class that is meant to be extended. You shouldn't ever use CNTDeviceService directly, unless extending it to provide support for an additional service/protocol.
 *
 * Immediately after discovery of a CNTDeviceService, CNTDiscoveryManager will set the CNTDeviceService's delegate to the CNTConnectableDevice that owns the CNTDeviceService. You should not change the delegate unless you intend to manage the lifecycle of that service. The CNTDeviceService will proxy all of its delegate method calls through the CNTConnectableDevice's CNTConnectableDeviceDelegate.
 *
 * ####Connection & Pairing
 * Your CNTConnectableDevice object will let you know if you need to connect or pair to any services.
 *
 * ####Capabilities
 * All CNTDeviceService objects have a group of capabilities. These capabilities can be implemented by any object, and that object will be returned when you call the CNTDeviceService's capability methods (launcher, mediaPlayer, volumeControl, etc).
 */
@interface CNTDeviceService : NSObject <CNTJSONObjectCoding>

/*!
 * Delegate object to receive CNTDeviceService status messages. See note in the "In Depth" section about changing the CNTDeviceServiceDelegate.
 */
@property (nonatomic, weak) id<CNTDeviceServiceDelegate>delegate;

/*! Object containing the discovered information about this CNTDeviceService */
@property (nonatomic, strong) CNTServiceDescription *serviceDescription;

/*! Object containing persistence data about this CNTDeviceService (pairing info, SSL certificates, etc) */
@property (nonatomic, strong) CNTServiceConfig *serviceConfig;

/*! Name of the CNTDeviceService (webOS, Chromecast, etc) */
@property (nonatomic, strong, readonly) NSString *serviceName;

/*!
 * A dictionary of keys/values that will be used by the CNTDiscoveryProvider used to discover this CNTDeviceService. Some keys that are used are: service name, SSDP filter, etc.
 */
+ (NSDictionary *) discoveryParameters;

/*!
 * Returns an instantiated CNTDeviceService of the proper subclass (CNTCastService, CNTWebOSTVService, etc).
 *
 * @property _class CNTDeviceService subclass to instantiate
 * @property serviceConfig CNTServiceConfig with configuration data of device (UUID, etc)
 */
+ (CNTDeviceService *)deviceServiceWithClass:(Class)_class serviceConfig:(CNTServiceConfig *)serviceConfig;

/*!
 * Returns an instantiated CNTDeviceService of the proper subclass (CNTCastService, CNTWebOSTVService, etc).
 *
 * @property serviceConfig CNTServiceConfig with configuration data of device (UUID, etc)
 */
- (instancetype) initWithServiceConfig:(CNTServiceConfig *)serviceConfig;

// @cond INTERNAL
+ (instancetype) deviceServiceWithJSONObject:(NSDictionary *)dict;
// @endcond

#pragma mark - Capabilities

/*!
 * An array of capabilities supported by the CNTDeviceService. This array may change based off a number of factors.
 * - CNTDiscoveryManager's pairingLevel value
 * - Connect SDK framework version
 * - First screen device OS version
 * - First screen device configuration (apps installed, settings, etc)
 * - Physical region
 */
@property (nonatomic, strong) NSArray *capabilities;

// @cond INTERNAL
- (void) updateCapabilities;
- (void) addCapability:(NSString *)capability;
- (void) addCapabilities:(NSArray *)capabilities;
- (void) removeCapability:(NSString *)capability;
- (void) removeCapabilities:(NSArray *)capabilities;
// @endcond

/*!
 * Test to see if the capabilities array contains a given capability. See the individual Capability classes for acceptable capability values.
 *
 * It is possible to append a wildcard search term `.Any` to the end of the search term. This method will return true for capabilities that match the term up to the wildcard.
 *
 * Example: `CNTLauncher.App.Any`
 *
 * @property capability Capability to test against
 */
- (BOOL) hasCapability:(NSString *)capability;

/*!
 * Test to see if the capabilities array contains a given set of capabilities. See the individual Capability classes for acceptable capability values.
 *
 * See hasCapability: for a description of the wildcard feature provided by this method.
 *
 * @property capabilities Array of capabilities to test against
 */
- (BOOL) hasCapabilities:(NSArray *)capabilities;

/*!
 * Test to see if the capabilities array contains at least one capability in a given set of capabilities. See the individual Capability classes for acceptable capability values.
 *
 * See hasCapability: for a description of the wildcard feature provided by this method.
 *
 * @property capabilities Array of capabilities to test against
 */
- (BOOL) hasAnyCapability:(NSArray *)capabilities;

#pragma mark - Connection

/*! Whether the CNTDeviceService is currently connected */
@property (nonatomic) BOOL connected;

/*! Whether the CNTDeviceService requires an active connection or registration process */
@property (nonatomic, readonly) BOOL isConnectable;

/*!
 * Will attempt to connect to the CNTDeviceService. The failure/success will be reported back to the CNTDeviceServiceDelegate. If the connection attempt reveals that pairing is required, the CNTDeviceServiceDelegate will also be notified in that event.
 */
- (void) connect;

/*!
 * Will attempt to disconnect from the CNTDeviceService. The failure/success will be reported back to the CNTDeviceServiceDelegate.
 */
- (void) disconnect;

# pragma mark - Pairing

/*! Whether the CNTDeviceService requires pairing or not. */
@property (nonatomic, readonly) BOOL requiresPairing;

/*! Type of pairing that this CNTDeviceService requires. May be unknown until you try to connect. */
@property (nonatomic, readwrite) DeviceServicePairingType pairingType;

/*! May contain useful information regarding pairing (pairing key length, etc) */
@property (nonatomic, readonly) id pairingData;

/*!
 * Will attempt to pair with the CNTDeviceService with the provided pairingData. The failure/success will be reported back to the CNTDeviceServiceDelegate.
 *
 * @param pairingData Data to be used for pairing. The type of this parameter will vary depending on what type of pairing is required, but is likely to be a string (pin code, pairing key, etc).
 */
- (void) pairWithData:(id)pairingData;

#pragma mark - Utility

/*!
 * Static property that determines whether a CNTDeviceService subclass should shut down communication channels when the app enters a background state. This may be helpful for apps that need to communicate with web apps from the background. This property may not be applicable to all CNTDeviceService subclasses.
 */
+ (BOOL) shouldDisconnectOnBackground;

/*!
 * Sets the shouldDisconnectOnBackground static property. This property should be set before starting CNTDiscoveryManager for the first time.
 *
 * @property shouldDisconnectOnBackground New value for CNTDeviceService.shouldDisconnectOnBackground
 */
+ (void) setShouldDisconnectOnBackround:(BOOL)shouldDisconnectOnBackground;

// @cond INTERNAL
void dispatch_on_main(dispatch_block_t block);
id ensureString(id value);
// @endcond

/*!
 * Every CNTLaunchSession object has an associated CNTDeviceService. Internally, CNTLaunchSession's close method proxies to it's CNTDeviceService's closeLaunchSession method. If, for some reason, your CNTLaunchSession loses it's CNTDeviceService reference, you can call this closeLaunchSession method directly.
 *
 * @param launchSession CNTLaunchSession to be closed
 * @param success (optional) SuccessBlock to be called on success
 * @param failure (optional) FailureBlock to be called on failure
 */
- (void) closeLaunchSession:(CNTLaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
