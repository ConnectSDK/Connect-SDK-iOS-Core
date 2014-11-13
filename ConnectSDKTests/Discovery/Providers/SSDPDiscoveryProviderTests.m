//
//  SSDPDiscoveryProviderTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 11/11/14.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import "SSDPDiscoveryProvider_Private.h"
#import "SSDPSocketListener.h"

static NSString *const kSSDPMulticastIPAddress = @"239.255.255.250";
static const NSUInteger kSSDPMulticastTCPPort = 1900;

static inline NSString *httpHeaderValue(CFHTTPMessageRef msg, NSString *header) {
    return CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(msg, (__bridge CFStringRef)header));
}


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

- (void)testStartDiscoveryShouldSendSearchRequest {
    // Arrange
    id searchSocketMock = OCMClassMock([SSDPSocketListener class]);
    self.provider.searchSocket = searchSocketMock;

    NSString *const kKeySSDP = @"ssdp";
    NSString *const kKeyFilter = @"filter";

    NSDictionary *filter = @{kKeySSDP: @{kKeyFilter: @"some:thing"}};
    [self.provider addDeviceFilter:filter];

    // Act
    [self.provider startDiscovery];

    // Assert
    BOOL (^httpDataVerificationBlock)(id obj) = ^BOOL(NSData *data) {
        CFHTTPMessageRef msg = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, YES);
        XCTAssertTrue(CFHTTPMessageAppendBytes(msg, data.bytes, data.length),
                      @"Couldn't parse the HTTP request");

        // assert the SSDP search request is according to the UPnP specification
        NSString *statusLine = [@[CFBridgingRelease(CFHTTPMessageCopyRequestMethod(msg)),
                                  CFBridgingRelease(CFURLCopyPath(CFHTTPMessageCopyRequestURL(msg))),
                                  CFBridgingRelease(CFHTTPMessageCopyVersion(msg))] componentsJoinedByString:@" "];
        XCTAssertEqualObjects(statusLine, @"M-SEARCH * HTTP/1.1", @"The status line is incorrect");

        NSString *host = httpHeaderValue(msg, @"HOST");
        NSString *correctHost = [NSString stringWithFormat:@"%@:%ld", kSSDPMulticastIPAddress, kSSDPMulticastTCPPort];
        XCTAssertEqualObjects(host, correctHost, @"The HOST header value is incorrect");

        NSString *man = httpHeaderValue(msg, @"MAN");
        XCTAssertEqualObjects(man, @"\"ssdp:discover\"", @"The MAN header value is incorrect");

        NSInteger mx = [httpHeaderValue(msg, @"MX") integerValue];
        XCTAssertGreaterThan(mx, 1, @"The MX header value must be > 1");
        XCTAssertLessThanOrEqual(mx, 5, @"The MX header value must be <= 5");

        NSString *searchTarget = httpHeaderValue(msg, @"ST");
        XCTAssertEqualObjects(searchTarget, filter[kKeySSDP][kKeyFilter], @"The Search Target header value is incorrect");

        NSString *userAgent = httpHeaderValue(msg, @"USER-AGENT");
        if (userAgent) {
            XCTAssertNotEqual([userAgent rangeOfString:@"UPnP/1.1"].location, NSNotFound,
                              @"The User Agent header value must include UPnP version");
        }

        NSData *body = CFBridgingRelease(CFHTTPMessageCopyBody(msg));
        XCTAssertEqual(body.length, 0, @"There must be no body");

        return YES;
    };

    OCMVerify([searchSocketMock sendData:[OCMArg checkWithBlock:httpDataVerificationBlock]
                               toAddress:kSSDPMulticastIPAddress
                                 andPort:kSSDPMulticastTCPPort]);
}

@end
