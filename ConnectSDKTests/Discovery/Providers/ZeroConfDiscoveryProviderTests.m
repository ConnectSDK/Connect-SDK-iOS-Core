//
//  ZeroConfDiscoveryProviderTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 11/18/14.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <arpa/inet.h>

#import <OCMock/OCMock.h>

#import "ZeroConfDiscoveryProvider_Private.h"
#import "ServiceDescription.h"

static NSString *const kKeyZeroconf = @"zeroconf";
static NSString *const kKeyFilter = @"filter";
static NSString *const kKeyServiceID = @"serviceId";

static const CGFloat kDefaultAsyncTestTimeout = 2.0f;


/// Tests for the ZeroConfDiscoveryProvider class.
@interface ZeroConfDiscoveryProviderTests : XCTestCase

@property (nonatomic, strong) ZeroConfDiscoveryProvider *provider;

@end

@implementation ZeroConfDiscoveryProviderTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];

    self.provider = [ZeroConfDiscoveryProvider new];
}

- (void)tearDown {
    self.provider = nil;

    [super tearDown];
}

#pragma mark -

- (void)testStartDiscoveryShouldSearchForServices {
    // Arrange
    id serviceBrowserMock = OCMClassMock([NSNetServiceBrowser class]);
    self.provider.netServiceBrowser = serviceBrowserMock;

    NSString *serviceType = @"zerotest";
    NSDictionary *filter = @{kKeyZeroconf: @{kKeyFilter: serviceType}};
    [self.provider addDeviceFilter:filter];

    // Act
    [self.provider startDiscovery];

    // Assert
    OCMVerify([serviceBrowserMock searchForServicesOfType:serviceType
                                                 inDomain:@"local."]);
}

- (void)testStopDiscoveryShouldStopServiceBrowser {
    // Arrange
    id serviceBrowserMock = OCMClassMock([NSNetServiceBrowser class]);
    self.provider.netServiceBrowser = serviceBrowserMock;

    // Act
    [self.provider startDiscovery];
    [self.provider stopDiscovery];

    // Assert
    OCMVerify([serviceBrowserMock stop]);
}

- (void)testShouldResolveServiceAfterDiscovering {
    // Arrange
    id serviceBrowserMock = OCMClassMock([NSNetServiceBrowser class]);
    self.provider.netServiceBrowser = serviceBrowserMock;

    NSString *serviceType = @"zerotest";
    NSDictionary *filter = @{kKeyZeroconf: @{kKeyFilter: serviceType}};
    [self.provider addDeviceFilter:filter];

    id netServiceMock = OCMClassMock([NSNetService class]);
    OCMStub([netServiceMock name]).andReturn(@"zeroservice");

    OCMStub([serviceBrowserMock searchForServicesOfType:serviceType
                                               inDomain:[OCMArg isNotNil]]).andDo(^(NSInvocation *_) {
        [self.provider netServiceBrowser:serviceBrowserMock
                          didFindService:netServiceMock
                              moreComing:NO];
    });

    // Act
    [self.provider startDiscovery];

    // Assert
    [[[netServiceMock verify] ignoringNonObjectArgs] resolveWithTimeout:0];
}

- (void)testShouldCallDelegateDidFindServiceAfterResolvingService {
    // Arrange
    id serviceBrowserMock = OCMClassMock([NSNetServiceBrowser class]);
    self.provider.netServiceBrowser = serviceBrowserMock;

    id delegateMock = OCMProtocolMock(@protocol(DiscoveryProviderDelegate));
    self.provider.delegate = delegateMock;

    NSString *serviceType = @"zerotest";
    NSDictionary *filter = @{kKeyZeroconf: @{kKeyFilter: serviceType},
                             kKeyServiceID: @"ZeroService"};
    [self.provider addDeviceFilter:filter];

    id netServiceMock = OCMClassMock([NSNetService class]);
    OCMStub([netServiceMock name]).andReturn(@"zeroservice");
    OCMStub([(NSNetService *)netServiceMock type]).andReturn(serviceType);

    OCMStub([serviceBrowserMock searchForServicesOfType:serviceType
                                               inDomain:[OCMArg isNotNil]]).andDo(^(NSInvocation *_) {
        [self.provider netServiceBrowser:serviceBrowserMock
                          didFindService:netServiceMock
                              moreComing:NO];
    });

    NSString *kServiceAddress = @"10.8.8.8";
    static const NSUInteger kServicePort = 8889;

    struct sockaddr_in socket;
    bzero(&socket, sizeof(socket));
    socket.sin_family = AF_INET;
    socket.sin_port = htons(kServicePort);
    XCTAssertEqual(inet_pton(socket.sin_family, [kServiceAddress UTF8String], &socket.sin_addr), 1, @"Failed to prepare mocked IP address");
    NSData *socketData = [NSData dataWithBytes:&socket length:sizeof(socket)];
    NSArray *addresses = @[socketData];
    OCMStub([netServiceMock addresses]).andReturn(addresses);

    [[[[netServiceMock stub] ignoringNonObjectArgs] andDo:^(NSInvocation *_) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.provider netServiceDidResolveAddress:netServiceMock];
        });
    }] resolveWithTimeout:0];

    XCTestExpectation *didFindServiceExpectation = [self expectationWithDescription:@"didFindService: is called"];
    OCMExpect([delegateMock discoveryProvider:self.provider
                               didFindService:[OCMArg checkWithBlock:^BOOL(ServiceDescription *service) {
        XCTAssertEqualObjects(service.address, kServiceAddress, @"The service's address is incorrect");
        XCTAssertEqual(service.port, kServicePort, @"The port is incorrect");
        XCTAssertEqualObjects(service.serviceId, filter[kKeyServiceID], @"The service ID is incorrect");
        XCTAssertEqualObjects(service.UUID, [netServiceMock name], @"The UUID is incorrect");
        XCTAssertEqualObjects(service.friendlyName, [netServiceMock name], @"The friendly name is incorrect");
        XCTAssertNil(service.manufacturer, @"The manufacturer should be nil");
        XCTAssertNil(service.modelName, @"The model name should be nil");
        XCTAssertNil(service.modelDescription, @"The model description should be nil");
        XCTAssertNil(service.modelNumber, @"The model number should be nil");
        XCTAssertEqualObjects(service.commandURL.absoluteString, ([NSString stringWithFormat:@"http://%@:%lu/", kServiceAddress, (unsigned long)kServicePort]), @"The command URL is incorrect");
        XCTAssertNil(service.locationXML, @"The XML content should be nil");
//        XCTAssertEqualObjects(service.type, [(NSNetService *)netServiceMock type], @"The service type is incorrect");
//        XCTAssertEqualObjects(service.version, @"1", @"The version is incorrect");
        XCTAssertNil(service.serviceList, @"The service list should be nil");

        [didFindServiceExpectation fulfill];
        return YES;
    }]]);

    // Act
    [self.provider startDiscovery];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error, @"didFindService: isn't called");
                                     OCMVerifyAll(delegateMock);
                                 }];
}

- (void)testShouldCallDelegateDidLoseServiceAfterRemovingService {
    // Arrange
    id serviceBrowserMock = OCMClassMock([NSNetServiceBrowser class]);
    self.provider.netServiceBrowser = serviceBrowserMock;

    id delegateMock = OCMProtocolMock(@protocol(DiscoveryProviderDelegate));
    self.provider.delegate = delegateMock;

    NSString *serviceType = @"zerotest";
    NSDictionary *filter = @{kKeyZeroconf: @{kKeyFilter: serviceType},
                             kKeyServiceID: @"ZeroService"};
    [self.provider addDeviceFilter:filter];

    id netServiceMock = OCMClassMock([NSNetService class]);
    OCMStub([netServiceMock name]).andReturn(@"zeroservice");
    OCMStub([(NSNetService *)netServiceMock type]).andReturn(serviceType);

    OCMStub([serviceBrowserMock searchForServicesOfType:serviceType
                                               inDomain:[OCMArg isNotNil]]).andDo(^(NSInvocation *_) {
        [self.provider netServiceBrowser:serviceBrowserMock
                          didFindService:netServiceMock
                              moreComing:NO];
    });

    NSString *kServiceAddress = @"10.8.8.8";
    static const NSUInteger kServicePort = 8889;

    struct sockaddr_in socket;
    bzero(&socket, sizeof(socket));
    socket.sin_family = AF_INET;
    socket.sin_port = htons(kServicePort);
    XCTAssertEqual(inet_pton(socket.sin_family, [kServiceAddress UTF8String], &socket.sin_addr), 1, @"Failed to prepare mocked IP address");
    NSData *socketData = [NSData dataWithBytes:&socket length:sizeof(socket)];
    NSArray *addresses = @[socketData];
    OCMStub([netServiceMock addresses]).andReturn(addresses);

    [[[[netServiceMock stub] ignoringNonObjectArgs] andDo:^(NSInvocation *_) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.provider netServiceDidResolveAddress:netServiceMock];
        });
    }] resolveWithTimeout:0];

    XCTestExpectation *didFindServiceExpectation = [self expectationWithDescription:@"didFindService: is called"];

    __block ServiceDescription *foundService;
    OCMStub([delegateMock discoveryProvider:self.provider
                             didFindService:[OCMArg isNotNil]]).andDo(^(NSInvocation *inv) {
        __unsafe_unretained ServiceDescription *tmp;
        [inv getArgument:&tmp atIndex:3];
        foundService = tmp;

        [didFindServiceExpectation fulfill];
    });

    [self.provider startDiscovery];
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error, @"didFindService: isn't called");
                                     OCMVerifyAll(delegateMock);
                                 }];

    XCTestExpectation *didLoseServiceExpectation = [self expectationWithDescription:@"didLoseService: is called"];
    OCMExpect([delegateMock discoveryProvider:self.provider
                               didLoseService:[OCMArg checkWithBlock:^BOOL(ServiceDescription *service) {
        XCTAssertEqualObjects(service, foundService, @"The lost service is not the found one");

        [didLoseServiceExpectation fulfill];
        return YES;
    }]]);

    // Act
    [self.provider netServiceBrowser:serviceBrowserMock
                    didRemoveService:netServiceMock
                          moreComing:NO];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error, @"Lose service timeout");
                                     OCMVerifyAll(delegateMock);
                                 }];
}

@end
