//
//  ConnectSDKTests.m
//  ConnectSDKTests
//
//  Created by Eugene Nikolskyi on 11/11/14.
//  Copyright (c) 2014 LG Electronics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "ConnectSDKDefaultPlatforms.h"

/// Generic tests for the ConnectSDK.
@interface ConnectSDKTests : XCTestCase

@end

@implementation ConnectSDKTests

/// Tests that the default platforms list is defined and not empty.
- (void)testThereShouldBeDefaultPlatforms {
    NSDictionary *platforms = kConnectSDKDefaultPlatforms;
    XCTAssertGreaterThan(platforms.count, 0, @"The default platforms list must not be empty");
}

@end
