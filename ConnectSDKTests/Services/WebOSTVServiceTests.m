//
//  WebOSTVServiceTests.m
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

#import "WebOSTVService.h"

#import "XCTestCase+TaskTests.h"

static NSString *const kClientKey = @"clientKey";

/// Tests for the @c WebOSTVService class.
@interface WebOSTVServiceTests : XCTestCase

@end

@implementation WebOSTVServiceTests

#pragma mark - Unsupported Methods Tests

- (void)testGetDurationShouldReturnNotSupportedError {
    [self checkOperationShouldReturnNotSupportedErrorUsingBlock:
        ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
            WebOSTVService *service = [WebOSTVService new];
            [service getDurationWithSuccess:^(NSTimeInterval _) {
                    successVerifier(nil);
                }
                                    failure:failureVerifier];
        }];
}

- (void)testGetMediaMetadataShouldReturnNotSupportedError {
    [self checkOperationShouldReturnNotSupportedErrorUsingBlock:
        ^(SuccessBlock successVerifier, FailureBlock failureVerifier) {
            WebOSTVService *service = [WebOSTVService new];
            [service getMediaMetaDataWithSuccess:successVerifier
                                         failure:failureVerifier];
        }];
}

#pragma mark - ServiceConfig Setter Tests (Base <=> WebOS)

/* The setter tests below test different cases of setting various service
 * config objects and whether those throw an exception when a client key from
 * @c WebOSTVServiceConfig would be lost.
 */

- (void)testSwitching_Base_To_WebOSWithoutKey_ServiceConfigShouldNotThrowException {
    ServiceConfig *config = [ServiceConfig new];
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:config];

    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_Base_To_WebOSWithKey_ServiceConfigShouldNotThrowException {
    ServiceConfig *config = [ServiceConfig new];
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:config];

    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    webosConfig.clientKey = kClientKey;
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithoutKey_To_Base_ServiceConfigShouldNotThrowException {
    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:webosConfig];

    ServiceConfig *config = [ServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = config,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithKey_To_Base_ServiceConfigShouldThrowException {
    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    webosConfig.clientKey = kClientKey;
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:webosConfig];

    ServiceConfig *config = [ServiceConfig new];
    XCTAssertThrowsSpecificNamed(service.serviceConfig = config,
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Should throw exception because the key will disappear");
}

#pragma mark - ServiceConfig Setter Tests (WebOS <=> WebOS)

- (void)testSwitching_WebOSWithoutKey_To_WebOSWithoutKey_ServiceConfigShouldNotThrowException {
    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:webosConfig];

    WebOSTVServiceConfig *webosConfig2 = [WebOSTVServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithoutKey_To_WebOSWithKey_ServiceConfigShouldNotThrowException {
    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:webosConfig];

    WebOSTVServiceConfig *webosConfig2 = [WebOSTVServiceConfig new];
    webosConfig2.clientKey = kClientKey;
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithKey_To_WebOSWithKey_ServiceConfigShouldNotThrowException {
    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    webosConfig.clientKey = kClientKey;
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:webosConfig];

    WebOSTVServiceConfig *webosConfig2 = [WebOSTVServiceConfig new];
    webosConfig2.clientKey = @"anotherKey";
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = webosConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_WebOSWithKey_To_WebOSWithoutKey_ServiceConfigShouldThrowException {
    WebOSTVServiceConfig *webosConfig = [WebOSTVServiceConfig new];
    webosConfig.clientKey = kClientKey;
    WebOSTVService *service = [[WebOSTVService alloc] initWithServiceConfig:webosConfig];

    WebOSTVServiceConfig *webosConfig2 = [WebOSTVServiceConfig new];
    XCTAssertThrowsSpecificNamed(service.serviceConfig = webosConfig2,
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Should throw exception because the key will disappear");
}

@end
