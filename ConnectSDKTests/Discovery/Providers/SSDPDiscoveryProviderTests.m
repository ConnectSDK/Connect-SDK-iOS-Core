//
//  SSDPDiscoveryProviderTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 11/11/14.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "SSDPDiscoveryProvider.h"

/// Tests for the SSDPDiscoveryProvider class.
@interface SSDPDiscoveryProviderTests : XCTestCase

@property (nonatomic, strong) SSDPDiscoveryProvider *provider;

@end

@implementation SSDPDiscoveryProviderTests

#pragma mark - Setup

- (void)setUp {
    [super setUp];

    self.provider = [SSDPDiscoveryProvider new];
}

- (void)tearDown {
    self.provider = nil;

    [super tearDown];
}

#pragma mark - General tests

- (void)testShouldNotBeRunningAfterCreation {
    XCTAssertFalse(self.provider.isRunning, @"The provider must not be running after creation");
}

#pragma mark - Device Filters tests

- (void)testRemovingNilDeviceFilterShouldNotCrash {
    [self.provider removeDeviceFilter:nil];

    XCTAssert(YES, @"Removing nil device filter must not crash");
}

- (void)testRemovingUnknownDeviceFilterShouldNotCrash {
    NSDictionary *filter = @{@"ssdp": @{@"filter": @"some:thing"}};
    [self.provider removeDeviceFilter:filter];

    XCTAssert(YES, @"Removing not previously add device filter must not crash");
}

#pragma mark - Discovery & Delegate tests

- (void)testShouldBeRunningAfterDiscoveryStart {
    [self.provider startDiscovery];

    XCTAssertTrue(self.provider.isRunning, @"The provider should be running after discovery start");
}

@end
