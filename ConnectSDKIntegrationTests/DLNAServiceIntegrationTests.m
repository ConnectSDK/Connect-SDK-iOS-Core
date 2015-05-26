//
//  DLNAServiceIntegrationTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 5/26/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
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

#import "DiscoveryManager.h"
#import "DLNAService.h"
#import "SSDPDiscoveryProvider.h"

#import "EXPMatchers+matchRegex.h"

#pragma mark - Environment-specific constants

static NSString *const kExpectedDeviceName = @"Living Room - Sonos PLAY:1 Media Renderer";
static NSString *const kExpectedIPAddressRegex = @"192\\.168\\.1\\.\\d{1,3}";

#pragma mark -

SpecBegin(DLNAService)

describe(@"ConnectSDK", ^{
    it(@"should discover Sonos device in the network", ^{
        // the official way to access DiscoveryManager is through the singleton,
        // but that's no good for tests
        DiscoveryManager *manager = [DiscoveryManager new];
        // don't need to save any state information
        manager.deviceStore = nil;

        // use a custom delegate to avoid showing any UI and get the discovery
        // callbacks
        id delegateMock = OCMProtocolMock(@protocol(DiscoveryManagerDelegate));
        manager.delegate = delegateMock;

        // use DLNA service only
        [manager registerDeviceService:[DLNAService class]
                         withDiscovery:[SSDPDiscoveryProvider class]];

        // wait for a matching device
        waitUntil(^(DoneCallback done) {
            void (^deviceVerifier)(ConnectableDevice *) = ^void(ConnectableDevice *device) {
                expect(device.address).matchRegex(kExpectedIPAddressRegex);
                expect(device.id).notTo.beNil();
                expect([device serviceWithName:kConnectSDKDLNAServiceId]).notTo.beNil();
            };

            OCMStub([delegateMock discoveryManager:manager
                                     didFindDevice:
                     [OCMArg checkWithBlock:^BOOL(ConnectableDevice *device) {
                if ([kExpectedDeviceName isEqualToString:device.friendlyName]) {
                    deviceVerifier(device);
                    done();
                }

                return YES;
            }]]);

            [manager startDiscovery];
        });

        [manager stopDiscovery];
    });
});

SpecEnd
