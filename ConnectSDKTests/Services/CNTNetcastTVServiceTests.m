//
//  CNTNetcastTVServiceTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 3/24/15.
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

#import "CNTNetcastTVService_Private.h"
#import "CTXMLReader.h"

#import "NSInvocation+CNTObjectGetter.h"

static NSString *const kClientCode = @"nop";

/// Tests for the @c CNTNetcastTVService class.
@interface CNTNetcastTVServiceTests : XCTestCase

@property (nonatomic, strong) id serviceCommandDelegateMock;
@property (nonatomic, strong) CNTNetcastTVService *service;

@end

@implementation CNTNetcastTVServiceTests

- (void)setUp {
    [super setUp];
    self.serviceCommandDelegateMock = OCMProtocolMock(@protocol(CNTServiceCommandDelegate));
    self.service = [CNTNetcastTVService new];
    self.service.serviceCommandDelegate = self.serviceCommandDelegateMock;
}

- (void)tearDown {
    self.service = nil;
    self.serviceCommandDelegateMock = nil;
    [super tearDown];
}

#pragma mark - Request Generation Tests

/// Tests that @c -sendText:success:failure: creates a proper and valid
/// TextEdited XML request.
- (void)testSendTextShouldCreateProperRequest {
    // Arrange
    NSString *commandName = @"TextEdited";
    static NSString *const defaultText = @"Hello, <World> &]]> \"others'\\ ура ξ中]]>…";

    XCTestExpectation *commandIsSent = [self expectationWithDescription:
                                        [NSString stringWithFormat:@"%@ command is sent", commandName]];

    [OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                                withPayload:OCMOCK_NOTNIL
                                                      toURL:OCMOCK_ANY]) andDo:^(NSInvocation *inv) {
        NSString *xmlString = [inv objectArgumentAtIndex:1];
        XCTAssertNotNil(xmlString, @"XML request not found");

        NSError *error = nil;
        NSDictionary *dict = [CTXMLReader dictionaryForXMLString:xmlString
                                                           error:&error];
        XCTAssertNil(error, @"XML parsing error");
        XCTAssertNotNil(dict, @"Couldn't parse XML");

        NSDictionary *envelope = dict[@"envelope"];
        XCTAssertNotNil(envelope, @"envelope tag must be present");

        NSDictionary *api = envelope[@"api"];
        XCTAssertNotNil(api, @"api tag must be present");
        XCTAssertEqualObjects(api[@"type"], @"event", @"api.type is incorrect");

        XCTAssertEqualObjects([api valueForKeyPath:@"name.text"], commandName, @"api name is incorrect");
        XCTAssertEqualObjects([api valueForKeyPath:@"state.text"], @"Editing", @"api state is incorrect");
        XCTAssertEqualObjects([api valueForKeyPath:@"value.text"], defaultText, @"api value is incorrect");

        [commandIsSent fulfill];
    }];

    // Act
    [self.service sendText:defaultText
                   success:^(id responseObject) {
                       XCTFail(@"success?");
                   } failure:^(NSError *error) {
                       XCTFail(@"fail? %@", error);
                   }];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

/* The setter tests below test different cases of setting various service
 * config objects and whether those throw an exception when some important data
 * from @c CNTNetcastTVServiceConfig would be lost.
 */

#pragma mark - ServiceConfig Setter Tests (Base <=> Netcast)

- (void)testSwitching_Base_To_NetcastWithoutCode_ServiceConfigShouldNotThrowException {
    CNTServiceConfig *config = [CNTServiceConfig new];
    CNTNetcastTVService *service = [[CNTNetcastTVService alloc] initWithServiceConfig:config];

    CNTNetcastTVServiceConfig *netcastConfig = [CNTNetcastTVServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = netcastConfig,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_Base_To_NetcastWithCode_ServiceConfigShouldNotThrowException {
    CNTServiceConfig *config = [CNTServiceConfig new];
    CNTNetcastTVService *service = [[CNTNetcastTVService alloc] initWithServiceConfig:config];

    CNTNetcastTVServiceConfig *netcastConfig = [CNTNetcastTVServiceConfig new];
    netcastConfig.pairingCode = kClientCode;
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = netcastConfig,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_NetcastWithoutCode_To_Base_ServiceConfigShouldNotThrowException {
    CNTNetcastTVServiceConfig *netcastConfig = [CNTNetcastTVServiceConfig new];
    CNTNetcastTVService *service = [[CNTNetcastTVService alloc] initWithServiceConfig:netcastConfig];

    CNTServiceConfig *config = [CNTServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = config,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_NetcastWithCode_To_Base_ServiceConfigShouldThrowException {
    CNTNetcastTVServiceConfig *netcastConfig = [CNTNetcastTVServiceConfig new];
    netcastConfig.pairingCode = kClientCode;
    CNTNetcastTVService *service = [[CNTNetcastTVService alloc] initWithServiceConfig:netcastConfig];

    CNTServiceConfig *config = [CNTServiceConfig new];
    XCTAssertThrowsSpecificNamed(service.serviceConfig = config,
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Should throw exception because the code will disappear");
}

#pragma mark - ServiceConfig Setter Tests (Netcast <=> Netcast)

- (void)testSwitching_NetcastWithoutCode_To_NetcastWithoutCode_ServiceConfigShouldNotThrowException {
    CNTNetcastTVServiceConfig *netcastConfig = [CNTNetcastTVServiceConfig new];
    CNTNetcastTVService *service = [[CNTNetcastTVService alloc] initWithServiceConfig:netcastConfig];

    CNTNetcastTVServiceConfig *netcastConfig2 = [CNTNetcastTVServiceConfig new];
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = netcastConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_NetcastWithoutCode_To_NetcastWithCode_ServiceConfigShouldNotThrowException {
    CNTNetcastTVServiceConfig *netcastConfig = [CNTNetcastTVServiceConfig new];
    CNTNetcastTVService *service = [[CNTNetcastTVService alloc] initWithServiceConfig:netcastConfig];

    CNTNetcastTVServiceConfig *netcastConfig2 = [CNTNetcastTVServiceConfig new];
    netcastConfig2.pairingCode = kClientCode;
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = netcastConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_NetcastWithCode_To_NetcastWithCode_ServiceConfigShouldNotThrowException {
    CNTNetcastTVServiceConfig *netcastConfig = [CNTNetcastTVServiceConfig new];
    netcastConfig.pairingCode = kClientCode;
    CNTNetcastTVService *service = [[CNTNetcastTVService alloc] initWithServiceConfig:netcastConfig];

    CNTNetcastTVServiceConfig *netcastConfig2 = [CNTNetcastTVServiceConfig new];
    netcastConfig2.pairingCode = @"anotherCode";
    XCTAssertNoThrowSpecificNamed(service.serviceConfig = netcastConfig2,
                                  NSException,
                                  NSInternalInconsistencyException,
                                  @"Should not throw exception");
}

- (void)testSwitching_NetcastWithCode_To_NetcastWithoutCode_ServiceConfigShouldThrowException {
    CNTNetcastTVServiceConfig *netcastConfig = [CNTNetcastTVServiceConfig new];
    netcastConfig.pairingCode = kClientCode;
    CNTNetcastTVService *service = [[CNTNetcastTVService alloc] initWithServiceConfig:netcastConfig];

    CNTNetcastTVServiceConfig *netcastConfig2 = [CNTNetcastTVServiceConfig new];
    XCTAssertThrowsSpecificNamed(service.serviceConfig = netcastConfig2,
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Should throw exception because the code will disappear");
}

@end
