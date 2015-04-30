//
//  CNTConnectableDeviceStore.h
//  Connect SDK
//
//  Created by Jeremy White on 3/21/14.
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
#import "CNTConnectableDevice.h"

/*!
 * CNTConnectableDeviceStore is a protocol which can be implemented to save key information about ConnectableDevices that have been connected to. Any class which implements this protocol can be used as CNTDiscoveryManager's deviceStore.
 *
 * A default implementation, CNTDefaultConnectableDeviceStore, will be used by CNTDiscoveryManager if no other CNTConnectableDeviceStore is provided to CNTDiscoveryManager when startDiscovery is called.
 *
 * ###Privacy Considerations
 * If you chose to implement CNTConnectableDeviceStore, it is important to keep your users' privacy in mind.
 * - There should be UI elements in your app to
 *   + completely disable CNTConnectableDeviceStore
 *   + purge all data from CNTConnectableDeviceStore (removeAll)
 * - Your CNTConnectableDeviceStore implementation should
 *   + avoid tracking too much data (indefinitely storing all discovered devices)
 *   + periodically remove ConnectableDevices from the CNTConnectableDeviceStore if they haven't been used/connected in X amount of time
 */
@protocol CNTConnectableDeviceStore <NSObject>

/*!
 * Add a CNTConnectableDevice to the CNTConnectableDeviceStore. If the CNTConnectableDevice is already stored, it's record will be updated.
 *
 * @param device CNTConnectableDevice to add to the CNTConnectableDeviceStore
 */
- (void) addDevice:(CNTConnectableDevice *)device;

/*!
 * Updates a CNTConnectableDevice's record in the CNTConnectableDeviceStore. If the CNTConnectableDevice is not in the store, this call will be ignored.
 *
 * @param device CNTConnectableDevice to update in the CNTConnectableDeviceStore
 */
- (void) updateDevice:(CNTConnectableDevice *)device;

/*!
 * Removes a CNTConnectableDevice's record from the CNTConnectableDeviceStore.
 *
 * @param device CNTConnectableDevice to remove from the CNTConnectableDeviceStore
 */
- (void) removeDevice:(CNTConnectableDevice *)device;

/*!
 * Gets a CNTConnectableDevice object for a provided id. The id may be for the CNTConnectableDevice object or any of the device's DeviceServices.
 *
 * @param id Unique ID for a CNTConnectableDevice or any of its CNTDeviceService objects
 *
 * @return CNTConnectableDevice object if a matching id was found, otherwise will return nil
 */
- (CNTConnectableDevice *) deviceForId:(NSString *)id;

/*!
 * Gets a CNTServiceConfig object for a provided UUID. This is used by CNTDiscoveryManager to retain crucial service information between sessions (pairing code, etc).
 *
 * @param UUID Unique ID for the service
 *
 * @return CNTServiceConfig object if a matching UUID was found, otherwise will return nil
 */
- (CNTServiceConfig *) serviceConfigForUUID:(NSString *)UUID;

/*!
 * Clears out the CNTConnectableDeviceStore, removing all records.
 */
- (void) removeAll;

/*!
 * A dictionary containing information about all ConnectableDevices in the CNTConnectableDeviceStore. To get a strongly-typed CNTConnectableDevice object, use the `getDeviceForUUID:` method.
 */
@property (nonatomic, readonly) NSDictionary *storedDevices;

@end
