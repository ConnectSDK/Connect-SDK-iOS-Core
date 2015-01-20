//
//  SSDPDiscoveryProvider_FilteringTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/15/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "SSDPDiscoveryProvider_Private.h"
#import "DLNAService.h"
#import "NetcastTVService.h"
#import "SSDPSocketListener.h"

static const NSUInteger kSSDPMulticastTCPPort = 1900;


/// Tests for the @c SSDPDiscoveryProvider 's discovery and filtering features.
@interface SSDPDiscoveryProvider_FilteringTests : XCTestCase

@end

@implementation SSDPDiscoveryProvider_FilteringTests

#pragma mark - Filtering Tests

/// Tests that the @c SSDPDiscoveryProvider properly parses Sonos' XML device
/// description with DLNA filter only and accepts the service.
- (void)testShouldFindDLNAService_Sonos {
    [self checkShouldFindDevice:@"sonos"
       withExpectedFriendlyName:@"Office - Sonos PLAY:1 Media Renderer"
        usingDiscoveryProviders:@[[DLNAService class]]];
}

/// Tests that the @c SSDPDiscoveryProvider properly parses Sonos' XML device
/// description (without the root serviceList) with DLNA filter only and accepts
/// the service.
- (void)testShouldFindDLNAService_SonosBased_NoRootServices {
    [self checkShouldFindDevice:@"sonos_no_root_services"
       withExpectedFriendlyName:@"Office - Sonos PLAY:1 Media Renderer"
        usingDiscoveryProviders:@[[DLNAService class]]];
}

/// Tests that the @c SSDPDiscoveryProvider properly parses Xbox's XML device
/// description with DLNA filter only and accepts the service.
- (void)testShouldFindDLNAService_Xbox {
    [self checkShouldFindDevice:@"xbox"
       withExpectedFriendlyName:@"XboxOne"
        usingDiscoveryProviders:@[[DLNAService class]]];
}

/// Tests that the @c SSDPDiscoveryProvider properly parses Sonos' XML device
/// description with Netcast and DLNA filters (in this order!) and accepts the
/// service.
- (void)testShouldFindDLNAServiceConsideringNetcast_Sonos {
    // the Netcast, then DLNA order is crucial here, since the Netcast service
    // doesn't have any required services, thus short-circuiting the check for
    // all DLNA devices (both services have the same filter)
    [self checkShouldFindDevice:@"sonos"
       withExpectedFriendlyName:@"Office - Sonos PLAY:1 Media Renderer"
        usingDiscoveryProviders:@[[NetcastTVService class], [DLNAService class]]];
}

/// Tests that the @c SSDPDiscoveryProvider properly parses Sonos' XML device
/// description (without the root serviceList) with Netcast and DLNA filters (in
/// this order!) and accepts the service.
- (void)testShouldFindDLNAServiceConsideringNetcast_SonosBased_NoRootServices {
    [self checkShouldFindDevice:@"sonos_no_root_services"
       withExpectedFriendlyName:@"Office - Sonos PLAY:1 Media Renderer"
        usingDiscoveryProviders:@[[NetcastTVService class], [DLNAService class]]];
}

/// Tests that the @c SSDPDiscoveryProvider properly parses Xbox's XML device
/// description with Netcast and DLNA filters (in this order!) and accepts the
/// service.
- (void)testShouldFindDLNAServiceConsideringNetcast_Xbox {
    [self checkShouldFindDevice:@"xbox"
       withExpectedFriendlyName:@"XboxOne"
        usingDiscoveryProviders:@[[NetcastTVService class], [DLNAService class]]];
}

#pragma mark - Helpers

- (void)checkShouldFindDevice:(NSString *)device
     withExpectedFriendlyName:(NSString *)friendlyName
      usingDiscoveryProviders:(NSArray *)discoveryProviders {
    // Arrange
    SSDPDiscoveryProvider *provider = [SSDPDiscoveryProvider new];
    [discoveryProviders enumerateObjectsUsingBlock:^(Class class, NSUInteger idx, BOOL *stop) {
        [provider addDeviceFilter:[class discoveryParameters]];
    }];

    id searchSocketMock = OCMClassMock([SSDPSocketListener class]);
    provider.searchSocket = searchSocketMock;

    NSString *serviceType = [DLNAService discoveryParameters][@"ssdp"][@"filter"];
    OCMStub([searchSocketMock sendData:OCMOCK_NOTNIL
                             toAddress:OCMOCK_NOTNIL
                               andPort:kSSDPMulticastTCPPort]).andDo((^(NSInvocation *invocation) {
        NSString *searchResponse = [NSString stringWithFormat:
                                    @"HTTP/1.1 200 OK\r\n"
                                    @"CACHE-CONTROL: max-age=1800\r\n"
                                    @"Date: Thu, 01 Jan 1970 04:04:04 GMT\r\n"
                                    @"EXT:\r\n"
                                    @"LOCATION: http://127.1/\r\n"
                                    @"SERVER: Linux/4.2 UPnP/1.1 MagicDevice/1.0\r\n"
                                    @"ST: %@\r\n"
                                    @"USN: uuid:f21e800a-1000-ab08-8e5a-76f4fcb5e772::urn:schemas-upnp-org:device:thing:1\r\n"
                                    @"Content-Length: 0\r\n"
                                    @"\r\n",
                                    serviceType];
        NSData *searchResponseData = [searchResponse dataUsingEncoding:NSUTF8StringEncoding];

        [provider socket:searchSocketMock
          didReceiveData:searchResponseData
             fromAddress:@"127.2"];
    }));

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString *filename = OHPathForFileInBundle(([NSString stringWithFormat:@"ssdp_device_description_%@.xml", device]), nil);
        return [OHHTTPStubsResponse responseWithFileAtPath:filename
                                                statusCode:200
                                                   headers:nil];
    }];

    XCTestExpectation *didFindServiceExpectation = [self expectationWithDescription:@"Did find device with DLNA service"];

    id discoveryProviderDelegateMock = OCMProtocolMock(@protocol(DiscoveryProviderDelegate));
    provider.delegate = discoveryProviderDelegateMock;
    OCMExpect([discoveryProviderDelegateMock discoveryProvider:[OCMArg isEqual:provider]
                                                didFindService:[OCMArg checkWithBlock:^BOOL(ServiceDescription *service) {
        XCTAssertEqualObjects(service.friendlyName, friendlyName,
                              @"The device's friendlyName doesn't match");
        [didFindServiceExpectation fulfill];
        return YES;
    }]]);

    // Act
    [provider startDiscovery];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(discoveryProviderDelegateMock);
                                 }];
}

@end
