//
//  CNTWebOSTVServiceTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 3/25/15.
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

#import "CNTWebOSTVService.h"

static NSString *const kClientKey = @"clientKey";

/// Tests for the @c CNTWebOSTVService class.
@interface CNTWebOSTVServiceTests : XCTestCase

@end

@implementation CNTWebOSTVServiceTests

/* The setter tests below test different cases of setting various service
 * config objects and whether those throw an exception when a client key from
 * @c CNTWebOSTVServiceConfig would be lost.
 */

#pragma mark - ServiceConfig Setter Tests (Base <=> WebOS)

- (void)testSwitching_Base_To_WebOSWithoutKey_ServiceConfigShouldNotThrowException {
    CNTServiceConfig *config = [CNTServiceConfig new];
    CNTWebOSTVService *service = [[CNTWebOSTVService alloc] initWithServiceConfig:config];

    CNTWebOSTVServiceConfig *webosConfig = [CNTWebOSTVServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_Base_To_WebOSWithKey_ServiceConfigShouldNotThrowException {
    CNTServiceConfig *config = [CNTServiceConfig new];
    CNTWebOSTVService *service = [[CNTWebOSTVService alloc] initWithServiceConfig:config];

    CNTWebOSTVServiceConfig *webosConfig = [CNTWebOSTVServiceConfig new];
    webosConfig.clientKey = kClientKey;
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithoutKey_To_Base_ServiceConfigShouldNotThrowException {
    CNTWebOSTVServiceConfig *webosConfig = [CNTWebOSTVServiceConfig new];
    CNTWebOSTVService *service = [[CNTWebOSTVService alloc] initWithServiceConfig:webosConfig];

    CNTServiceConfig *config = [CNTServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = config,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithKey_To_Base_ServiceConfigShouldThrowException {
    CNTWebOSTVServiceConfig *webosConfig = [CNTWebOSTVServiceConfig new];
    webosConfig.clientKey = kClientKey;
    CNTWebOSTVService *service = [[CNTWebOSTVService alloc] initWithServiceConfig:webosConfig];

    CNTServiceConfig *config = [CNTServiceConfig new];
    XCTAssertThrowsSpecificNamed(service.serviceConfig = config,
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Should throw exception because the key will disappear");
}

#pragma mark - ServiceConfig Setter Tests (WebOS <=> WebOS)

- (void)testSwitching_WebOSWithoutKey_To_WebOSWithoutKey_ServiceConfigShouldNotThrowException {
    CNTWebOSTVServiceConfig *webosConfig = [CNTWebOSTVServiceConfig new];
    CNTWebOSTVService *service = [[CNTWebOSTVService alloc] initWithServiceConfig:webosConfig];

    CNTWebOSTVServiceConfig *webosConfig2 = [CNTWebOSTVServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithoutKey_To_WebOSWithKey_ServiceConfigShouldNotThrowException {
    CNTWebOSTVServiceConfig *webosConfig = [CNTWebOSTVServiceConfig new];
    CNTWebOSTVService *service = [[CNTWebOSTVService alloc] initWithServiceConfig:webosConfig];

    CNTWebOSTVServiceConfig *webosConfig2 = [CNTWebOSTVServiceConfig new];
    webosConfig2.clientKey = kClientKey;
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithKey_To_WebOSWithKey_ServiceConfigShouldNotThrowException {
    CNTWebOSTVServiceConfig *webosConfig = [CNTWebOSTVServiceConfig new];
    webosConfig.clientKey = kClientKey;
    CNTWebOSTVService *service = [[CNTWebOSTVService alloc] initWithServiceConfig:webosConfig];

    CNTWebOSTVServiceConfig *webosConfig2 = [CNTWebOSTVServiceConfig new];
    webosConfig2.clientKey = @"anotherKey";
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithKey_To_WebOSWithoutKey_ServiceConfigShouldThrowException {
    CNTWebOSTVServiceConfig *webosConfig = [CNTWebOSTVServiceConfig new];
    webosConfig.clientKey = kClientKey;
    CNTWebOSTVService *service = [[CNTWebOSTVService alloc] initWithServiceConfig:webosConfig];

    CNTWebOSTVServiceConfig *webosConfig2 = [CNTWebOSTVServiceConfig new];
    XCTAssertThrowsSpecificNamed(service.serviceConfig = webosConfig2,
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Should throw exception because the key will disappear");
}

@end
