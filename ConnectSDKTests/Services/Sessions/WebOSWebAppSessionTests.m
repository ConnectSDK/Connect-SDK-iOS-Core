//
//  WebOSWebAppSessionTests.m
//  ConnectSDK
//
//  Created by Ibrahim Adnan on 6/18/15.
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

#import "WebOSWebAppSession_Private.h"
#import "WebOSTVServiceSocketClient.h"

@interface WebOSWebAppSessionTests : XCTestCase

@end

@implementation WebOSWebAppSessionTests

- (void)testMediaPlayerErrorShouldCallFailureBlockInPlayStateSubscription{
    // Arrange
    id socketMock = OCMClassMock([WebOSTVServiceSocketClient class]);
    WebOSWebAppSession *session = OCMPartialMock([WebOSWebAppSession new]);
    OCMStub([session createSocketWithService:OCMOCK_ANY]).andReturn(socketMock);
    session.fullAppId = @"com.lgsmartplatform.redirect.MediaPlayer";

    XCTestExpectation *failureBlockCalledExpectation = [self expectationWithDescription:@"Failure block is called"];
    [session subscribePlayStateWithSuccess:^(MediaControlPlayState playState) {
         XCTFail(@"Success should not be called when Media player throws error");
    } failure:^(NSError *error) {
        [failureBlockCalledExpectation fulfill];
    }];

    NSDictionary *errorPayload = @{
                                   @"from" : @"com.lgsmartplatform.redirect.MediaPlayer",
                                   @"payload" : @{
                                           @"contentType" : @"connectsdk.media-error",
                                           @"error" : @"The file cannot be recognized",
                                           },
                                   @"type" : @"p2p"
                                   };

    // Act
    [session socket:socketMock didReceiveMessage:errorPayload];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout handler:nil];
}

@end
