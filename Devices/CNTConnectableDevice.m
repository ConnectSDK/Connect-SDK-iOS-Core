//
//  CNTConnectableDevice.m
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

#import "CNTConnectableDevice.h"
#import "CNTDLNAService.h"
#import "CNTMediaControl.h"
#import "CNTExternalInputControl.h"
#import "CNTToastControl.h"
#import "CNTTextInputControl.h"
#import "CTGuid.h"
#import "CNTDiscoveryManager.h"

@implementation CNTConnectableDevice
{
    NSMutableDictionary *_services;
}

@synthesize serviceDescription = _consolidatedServiceDescription;
@synthesize delegate = _delegate;
@synthesize id = _id;

- (instancetype) init
{
    self = [super init];

    if (self)
    {
        _consolidatedServiceDescription = [CNTServiceDescription new];
        _services = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (instancetype) initWithDescription:(CNTServiceDescription *)description
{
    self = [self init];

    if (self)
    {
        _consolidatedServiceDescription = description;
    }

    return self;
}

- (instancetype) initWithJSONObject:(NSDictionary *)dict
{
    self = [self init];

    if (self)
    {
        _id = dict[@"id"];
        _lastKnownIPAddress = dict[@"lastKnownIPAddress"];
        _lastSeenOnWifi = dict[@"lastSeenOnWifi"];

        id lastConnected = dict[@"lastConnected"];
        if (lastConnected && ![lastConnected isKindOfClass:[NSNull class]])
            _lastConnected = [lastConnected doubleValue];

        id lastDetection = dict[@"lastDetection"];
        if (lastDetection && ![lastDetection isKindOfClass:[NSNull class]])
            _lastDetection = [lastDetection doubleValue];

        if (!self.address)
            _consolidatedServiceDescription.address = _lastKnownIPAddress;
    }

    return self;
}

- (NSDictionary *) toJSONObject
{
    NSMutableDictionary *jsonObject = [NSMutableDictionary new];

    if (self.id) jsonObject[@"id"] = self.id;
    if (self.friendlyName) jsonObject[@"friendlyName"] = self.friendlyName;
    if (self.lastKnownIPAddress) jsonObject[@"lastKnownIPAddress"] = self.lastKnownIPAddress;
    if (self.lastSeenOnWifi) jsonObject[@"lastSeenOnWifi"] = self.lastSeenOnWifi;
    if (self.lastConnected) jsonObject[@"lastConnected"] = @(self.lastConnected);
    if (self.lastDetection) jsonObject[@"lastDetection"] = @(self.lastDetection);

    NSMutableDictionary *services = [NSMutableDictionary new];

    [self.services enumerateObjectsUsingBlock:^(CNTDeviceService *service, NSUInteger idx, BOOL *stop)
    {
        NSDictionary *serviceJSON = [service toJSONObject];
        [services setObject:serviceJSON forKey:service.serviceDescription.UUID];
    }];

    if (services.count > 0)
        jsonObject[@"services"] = [NSDictionary dictionaryWithDictionary:services];

    return jsonObject;
}

+ (instancetype) connectableDeviceWithDescription:(CNTServiceDescription *)description
{
    return [[CNTConnectableDevice alloc] initWithDescription:description];
}

- (void) setDelegate:(id<CNTConnectableDeviceDelegate>)delegate
{
    _delegate = delegate;

    if (_delegate && [self.delegate respondsToSelector:@selector(connectableDeviceConnectionRequired:forService:)])
    {
        [_services enumerateKeysAndObjectsUsingBlock:^(id key, CNTDeviceService *service, BOOL *stop) {
            if (service.isConnectable && !service.connected)
                [_delegate connectableDeviceConnectionRequired:self forService:service];
        }];
    }
}

#pragma mark - General info

- (NSString *) id
{
    if (!_id)
        _id = [[CTGuid randomGuid] stringValueWithFormat:CTGuidFormatDashed];

    return _id;
}

- (NSString *) address
{
    return _consolidatedServiceDescription.address;
}

- (NSString *) friendlyName
{
    return _consolidatedServiceDescription.friendlyName;
}

- (NSString *) modelName
{
    return _consolidatedServiceDescription.modelName;
}

- (NSString *) modelNumber
{
    return _consolidatedServiceDescription.modelNumber;
}

- (NSString *) connectedServiceNames
{
    __block NSString *serviceNames = @"";

    if (_services.count == 0)
        return serviceNames;

    [_services enumerateKeysAndObjectsUsingBlock:^(NSString * key, CNTDeviceService *service, BOOL *stop) {
        serviceNames = [serviceNames stringByAppendingString:[NSString stringWithFormat:@"%@, ", key]];
    }];

    serviceNames = [serviceNames substringToIndex:serviceNames.length - 2];

    return serviceNames;
}

- (BOOL) connected
{
    __block int connectedCount = 0;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, CNTDeviceService *service, BOOL *stop)
    {
        if (!service.isConnectable)
            connectedCount++;
        else
        {
            if (service.connected)
                connectedCount++;
        }
    }];

    return connectedCount >= _services.count;
}

- (void) connect
{
    if (self.connected)
    {
        dispatch_on_main(^{ [self.delegate connectableDeviceReady:self]; });
    } else
    {
        [_services enumerateKeysAndObjectsUsingBlock:^(id key, CNTDeviceService *service, BOOL *stop)
        {
            if (!service.connected)
                [service connect];
        }];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnect) name:kCNTConnectSDKWirelessSSIDChanged object:nil];
}

- (void) disconnect
{
    [_services enumerateKeysAndObjectsUsingBlock:^(id key, CNTDeviceService *service, BOOL *stop)
    {
        if (service.connected)
            [service disconnect];
    }];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCNTConnectSDKWirelessSSIDChanged object:nil];

    dispatch_on_main(^{ [self.delegate connectableDeviceDisconnected:self withError:nil]; });
}

- (BOOL) isConnectable
{
    __block BOOL connectable = NO;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, CNTDeviceService *service, BOOL *stop)
    {
        if (service.isConnectable)
        {
            connectable = YES;
            *stop = YES;
        }
    }];

    return connectable;
}

- (int) connectedServiceCount
{
    __block int count = 0;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, CNTDeviceService *service, BOOL *stop)
    {
        if ([service isConnectable])
        {
            if (service.connected)
                count++;
        } else
        {
            count++;
        }

    }];

    return count;
}

- (int) connectableServiceCount
{
    __block int count = 0;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, CNTDeviceService *service, BOOL *stop)
    {
        if ([service isConnectable])
            count++;
    }];

    return count;
}

#pragma mark - Service management

- (NSArray *) services
{
    return [_services allValues];
}

- (BOOL) hasServices
{
    return _services.count > 0;
}

- (void) addService:(CNTDeviceService *)service
{
    CNTDeviceService *existingService = [_services objectForKey:service.serviceName];

    NSArray *oldCapabilities = self.capabilities;

    if (existingService)
    {
        if (service.serviceDescription.lastDetection > existingService.serviceDescription.lastDetection)
        {
            if (existingService.connected)
                [existingService disconnect];

            DLog(@"Removing %@ (%@)", existingService.serviceDescription.friendlyName, existingService.serviceName);
            [self removeServiceWithId:existingService.serviceName];
        } else
        {
            DLog(@"Ignoring %@ (%@)", service.serviceDescription.friendlyName, service.serviceName);
            return;
        }
    }

    [_services setObject:service forKey:service.serviceName];
    
    if (service.delegate == nil)
        service.delegate = self;

    if (service.isConnectable && !service.connected)
    {
        if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDeviceConnectionRequired:forService:)])
            dispatch_on_main(^{ [_delegate connectableDeviceConnectionRequired:self forService:service]; });
    }

    [self updateCapabilitiesList:oldCapabilities];

    [self updateConsolidatedServiceDescription:service.serviceDescription];
}

- (void) removeServiceWithId:(NSString *)serviceId
{
    CNTDeviceService *service = [_services objectForKey:serviceId];

    if (service == nil)
        return;

    NSArray *oldCapabilities = self.capabilities;

    [service disconnect];

    [_services removeObjectForKey:serviceId];

    [self updateCapabilitiesList:oldCapabilities];
}

- (void) updateCapabilitiesList:(NSArray *)oldCapabilities
{
    NSArray *newCapabilities = self.capabilities;

    NSMutableArray *removedCapabilities = [NSMutableArray new];

    [oldCapabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop) {
        if (![newCapabilities containsObject:capability])
            [removedCapabilities addObject:capability];
    }];

    NSMutableArray *addedCapabilities = [NSMutableArray new];

    [newCapabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop) {
        if (![oldCapabilities containsObject:capability])
            [addedCapabilities addObject:capability];
    }];

    NSArray *added = [NSArray arrayWithArray:addedCapabilities];
    NSArray *removed = [NSArray arrayWithArray:removedCapabilities];

    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevice:capabilitiesAdded:removed:)])
        dispatch_on_main(^{ [self.delegate connectableDevice:self capabilitiesAdded:added removed:removed]; });
}

- (void) updateConsolidatedServiceDescription:(CNTServiceDescription *)serviceDescription
{
    if (serviceDescription.address)
        _consolidatedServiceDescription.address = serviceDescription.address;

    if (serviceDescription.friendlyName)
        _consolidatedServiceDescription.friendlyName = serviceDescription.friendlyName;

    if (serviceDescription.modelName)
        _consolidatedServiceDescription.modelName = serviceDescription.modelName;

    if (serviceDescription.modelNumber)
        _consolidatedServiceDescription.modelNumber = serviceDescription.modelNumber;
}

- (CNTDeviceService *)serviceWithName:(NSString *)serviceId
{
    __block CNTDeviceService *foundService;

    [_services enumerateKeysAndObjectsUsingBlock:^(NSString *id, CNTDeviceService *service, BOOL *stop)
    {
        if ([id isEqualToString:serviceId])
        {
            foundService = service;
            *stop = YES;
        }
    }];

    return foundService;
}

#pragma mark - DeviceServiceDelegate
#pragma mark Connection

- (void)deviceServiceConnectionRequired:(CNTDeviceService *)service
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDeviceConnectionRequired:forService:)])
        dispatch_on_main(^{ [self.delegate connectableDeviceConnectionRequired:self forService:service]; });
}

- (void)deviceServiceConnectionSuccess:(CNTDeviceService *)service
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDeviceConnectionSuccess:forService:)])
        dispatch_on_main(^{ [self.delegate connectableDeviceConnectionSuccess:self forService:service]; });

    if (self.connected)
    {
        [[[CNTDiscoveryManager sharedManager] deviceStore] addDevice:self];

        dispatch_on_main(^{ [self.delegate connectableDeviceReady:self]; });

        self.lastConnected = [[NSDate date] timeIntervalSince1970];
    }
}

- (void)deviceService:(CNTDeviceService *)service didFailConnectWithError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevice:connectionFailedWithError:)])
        dispatch_on_main(^{ [self.delegate connectableDevice:self connectionFailedWithError:error]; });

    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevice:service:didFailConnectWithError:)])
        dispatch_on_main(^{ [self.delegate connectableDevice:self service:service didFailConnectWithError:error]; });
}

- (void)deviceService:(CNTDeviceService *)service disconnectedWithError:(NSError *)error
{
    // TODO: need to aggregate errors between disconnects
    if ([self connectedServiceCount] == 0 || _services.count == 0)
        dispatch_on_main(^{ [self.delegate connectableDeviceDisconnected:self withError:error]; });

    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevice:service:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate connectableDevice:self service:service disconnectedWithError:error]; });
}

#pragma mark Pairing

- (void)setPairingType:(CNTDeviceServicePairingType)pairingType {
    [self.services enumerateObjectsUsingBlock:^(CNTDeviceService *service, NSUInteger serviceIdx, BOOL *serviceStop)
     {
         service.pairingType = pairingType;
     }];
}

- (void)deviceService:(CNTDeviceService *)service pairingRequiredOfType:(CNTDeviceServicePairingType)pairingType withData:(id)pairingData
{
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(connectableDevice:service:pairingRequiredOfType:withData:)])
            dispatch_on_main(^{ [self.delegate connectableDevice:self service:service pairingRequiredOfType:pairingType withData:pairingData]; });
        else
        {
            if (pairingType == CNTDeviceServicePairingTypeAirPlayMirroring)
                [(UIAlertView *)pairingData show];
        }
    }
}

- (void)deviceServicePairingSuccess:(CNTDeviceService *)service
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevicePairingSuccess:service:)])
        dispatch_on_main(^{ [self.delegate connectableDevicePairingSuccess:self service:service]; });
}

- (void)deviceService:(CNTDeviceService *)service pairingFailedWithError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevice:service:pairingFailedWithError:)])
        dispatch_on_main(^{ [self.delegate connectableDevice:self service:service pairingFailedWithError:error]; });
}

#pragma mark Capability updates

- (void) deviceService:(CNTDeviceService *)service capabilitiesAdded:(NSArray *)added removed:(NSArray *)removed
{
    [[CNTDiscoveryManager sharedManager] connectableDevice:self capabilitiesAdded:added removed:removed];

    if (self.delegate && [self.delegate respondsToSelector:@selector(connectableDevice:capabilitiesAdded:removed:)])
        dispatch_on_main(^{ [self.delegate connectableDevice:self capabilitiesAdded:added removed:removed]; });
}

#pragma mark - Capabilities

- (NSArray *) capabilities
{
    NSMutableArray *caps = [NSMutableArray new];

    [self.services enumerateObjectsUsingBlock:^(CNTDeviceService *service, NSUInteger serviceIdx, BOOL *serviceStop)
    {
        [service.capabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger capabilityIdx, BOOL *capabilityStop)
        {
            if (![caps containsObject:capability])
                [caps addObject:capability];
        }];
    }];

    return [NSArray arrayWithArray:caps];
}

- (BOOL) hasCapability:(NSString *)capability
{
    __block BOOL hasCap = NO;

    [self.services enumerateObjectsUsingBlock:^(CNTDeviceService *service, NSUInteger idx, BOOL *stop)
    {
        if ([service hasCapability:capability])
        {
            hasCap = YES;
            *stop = YES;
        }
    }];

    return hasCap;
}

- (BOOL) hasCapabilities:(NSArray *)capabilities
{
    __block BOOL hasCaps = YES;

    [capabilities enumerateObjectsUsingBlock:^(NSString *capability, NSUInteger idx, BOOL *stop)
    {
        if (![self hasCapability:capability])
        {
            hasCaps = NO;
            *stop = YES;
        }
    }];

    return hasCaps;
}

- (BOOL) hasAnyCapability:(NSArray *)capabilities
{
    __block BOOL hasCap = NO;

    [self.services enumerateObjectsUsingBlock:^(CNTDeviceService *service, NSUInteger idx, BOOL *stop)
    {
        if ([service hasAnyCapability:capabilities])
        {
            hasCap = YES;
            *stop = YES;
        }
    }];

    return hasCap;
}

- (id<CNTLauncher>) launcher
{
    __block id<CNTLauncher> foundLauncher;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(launcher)])
            return;

        id<CNTLauncher> launcher = [service launcher];

        if (launcher)
        {
            if (foundLauncher)
            {
                if (launcher.launcherPriority > foundLauncher.launcherPriority)
                {
                    foundLauncher = launcher;
                }
            } else
            {
                foundLauncher = launcher;
            }
        }
    }];

    return foundLauncher;
}

- (id<CNTExternalInputControl>)externalInputControl
{
    __block id<CNTExternalInputControl> foundExternalInputControl;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(externalInputControl)])
            return;

        id<CNTExternalInputControl> externalInputControl = [service externalInputControl];

        if (externalInputControl)
        {
            if (foundExternalInputControl)
            {
                if (externalInputControl.externalInputControlPriority > foundExternalInputControl.externalInputControlPriority)
                {
                    foundExternalInputControl = externalInputControl;
                }
            } else
            {
                foundExternalInputControl = externalInputControl;
            }
        }
    }];

    return foundExternalInputControl;
}

- (id<CNTMediaPlayer>) mediaPlayer
{
    __block id<CNTMediaPlayer> foundPlayer;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(mediaPlayer)])
            return;

        id<CNTMediaPlayer> player = [service mediaPlayer];

        if (player)
        {
            if (foundPlayer)
            {
                if (player.mediaPlayerPriority > foundPlayer.mediaPlayerPriority)
                {
                    foundPlayer = player;
                }
            } else
            {
                foundPlayer = player;
            }
        }
    }];

    return foundPlayer;
}

- (id<CNTMediaControl>) mediaControl
{
    __block id<CNTMediaControl> foundMediaControl;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(mediaControl)])
            return;

        id<CNTMediaControl> mediaControl = [service mediaControl];

        if (mediaControl)
        {
            if (foundMediaControl)
            {
                if (mediaControl.mediaControlPriority > foundMediaControl.mediaControlPriority)
                {
                    foundMediaControl = mediaControl;
                }
            } else
            {
                foundMediaControl = mediaControl;
            }
        }
    }];

    return foundMediaControl;
}

- (id<CNTVolumeControl>)volumeControl
{
    __block id<CNTVolumeControl> foundVolume;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(volumeControl)])
            return;

        id<CNTVolumeControl> volume = [service volumeControl];

        if (volume)
        {
            if (foundVolume)
            {
                if (volume.volumeControlPriority > foundVolume.volumeControlPriority)
                {
                    foundVolume = volume;
                }
            } else
            {
                foundVolume = volume;
            }
        }
    }];

    return foundVolume;
}

- (id<CNTTVControl>)tvControl
{
    __block id<CNTTVControl> foundTV;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(tvControl)])
            return;

        id<CNTTVControl> tv = [service tvControl];

        if (tv)
        {
            if (foundTV)
            {
                if (tv.tvControlPriority > foundTV.tvControlPriority)
                {
                    foundTV = tv;
                }
            } else
            {
                foundTV = tv;
            }
        }
    }];

    return foundTV;
}

- (id<CNTKeyControl>) keyControl
{
    __block id<CNTKeyControl> foundKeyControl;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(keyControl)])
            return;

        id<CNTKeyControl> keyControl = [service keyControl];

        if (keyControl)
        {
            if (foundKeyControl)
            {
                if (keyControl.keyControlPriority > foundKeyControl.keyControlPriority)
                {
                    foundKeyControl = keyControl;
                }
            } else
            {
                foundKeyControl = keyControl;
            }
        }
    }];

    return foundKeyControl;
}

- (id<CNTTextInputControl>) textInputControl
{
    __block id<CNTTextInputControl> foundTextInput;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(textInputControl)])
            return;

        id<CNTTextInputControl> textInput = [service textInputControl];

        if (textInput)
        {
            if (foundTextInput)
            {
                if (textInput.textInputControlPriority > foundTextInput.textInputControlPriority)
                {
                    foundTextInput = textInput;
                }
            } else
            {
                foundTextInput = textInput;
            }
        }
    }];

    return foundTextInput;
}

- (id<CNTMouseControl>)mouseControl
{
    __block id<CNTMouseControl> foundMouse;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(mouseControl)])
            return;

        id<CNTMouseControl> mouse = [service mouseControl];

        if (mouse)
        {
            if (foundMouse)
            {
                if (mouse.mouseControlPriority > foundMouse.mouseControlPriority)
                {
                    foundMouse = mouse;
                }
            } else
            {
                foundMouse = mouse;
            }
        }
    }];

    return foundMouse;
}

- (id<CNTPowerControl>)powerControl
{
    __block id<CNTPowerControl> foundPower;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(powerControl)])
            return;

        id<CNTPowerControl> power = [service powerControl];

        if (power)
        {
            if (foundPower)
            {
                if (power.powerControlPriority > foundPower.powerControlPriority)
                {
                    foundPower = power;
                }
            } else
            {
                foundPower = power;
            }
        }
    }];

    return foundPower;
}

- (id<CNTToastControl>) toastControl
{
    __block id<CNTToastControl> foundToastControl;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(toastControl)])
            return;

        id<CNTToastControl> toastControl = [service toastControl];

        if (toastControl)
        {
            if (foundToastControl)
            {
                if (toastControl.toastControlPriority > foundToastControl.toastControlPriority)
                {
                    foundToastControl = toastControl;
                }
            } else
            {
                foundToastControl = toastControl;
            }
        }
    }];

    return foundToastControl;
}

- (id<CNTWebAppLauncher>) webAppLauncher
{
    __block id<CNTWebAppLauncher> foundWebAppLauncher;

    [_services enumerateKeysAndObjectsUsingBlock:^(id key, id service, BOOL *stop)
    {
        if (![service respondsToSelector:@selector(webAppLauncher)])
            return;

        id<CNTWebAppLauncher> webAppLauncher = [service webAppLauncher];

        if (webAppLauncher)
        {
            if (foundWebAppLauncher)
            {
                if (webAppLauncher.webAppLauncherPriority > foundWebAppLauncher.webAppLauncherPriority)
                {
                    foundWebAppLauncher = webAppLauncher;
                }
            } else
            {
                foundWebAppLauncher = webAppLauncher;
            }
        }
    }];

    return foundWebAppLauncher;
}

@end
