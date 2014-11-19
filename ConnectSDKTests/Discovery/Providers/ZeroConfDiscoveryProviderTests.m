//
//  ZeroConfDiscoveryProviderTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 11/18/14.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "ZeroConfDiscoveryProvider_Private.h"

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
    NSDictionary *filter = @{@"zeroconf": @{@"filter": serviceType}};
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

@end
