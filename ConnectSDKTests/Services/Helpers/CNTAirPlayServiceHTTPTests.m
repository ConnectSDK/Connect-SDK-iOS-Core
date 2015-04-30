//
//  CNTAirPlayServiceHTTPTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 4/21/15.
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

#import "CNTAirPlayService.h"
#import "CNTAirPlayServiceHTTP_Private.h"

#import "NSInvocation+CNTObjectGetter.h"

/// Tests for the @c CNTAirPlayServiceHTTP class.
@interface CNTAirPlayServiceHTTPTests : XCTestCase

@end

@implementation CNTAirPlayServiceHTTPTests

#pragma mark - getPlayState Tests

/// Tests that @c -getPlayStateWithSuccess:failure: properly infers the Paused
/// play state from a sample playback-info response.
- (void)testGetPlayStateShouldReturnPausedWhenRateIsZero {
    [self checkGetPlayStateShouldReturnPlayState:MediaControlPlayStatePaused
                           forMockResponseInFile:@"airplay_playbackinfo_paused"];
}

/// Tests that @c -getPlayStateWithSuccess:failure: properly infers the Playing
/// play state from a sample playback-info response.
- (void)testGetPlayStateShouldReturnPlayingWhenRateIsOne {
    [self checkGetPlayStateShouldReturnPlayState:MediaControlPlayStatePlaying
                           forMockResponseInFile:@"airplay_playbackinfo_playing"];
}

/// Tests that @c -getPlayStateWithSuccess:failure: properly infers the Playing
/// play state from a sample playback-info response.
- (void)testGetPlayStateShouldReturnPlayingWhenRateIsTwo {
    [self checkGetPlayStateShouldReturnPlayState:MediaControlPlayStatePlaying
                           forMockResponseInFile:@"airplay_playbackinfo_ff"];
}

/// Tests that @c -getPlayStateWithSuccess:failure: properly infers the Playing
/// play state from a sample playback-info response.
- (void)testGetPlayStateShouldReturnPlayingWhenRateIsMinusTwo {
    [self checkGetPlayStateShouldReturnPlayState:MediaControlPlayStatePlaying
                           forMockResponseInFile:@"airplay_playbackinfo_rewind"];
}

/// Tests that @c -getPlayStateWithSuccess:failure: properly infers the Finished
/// play state from a sample playback-info response.
- (void)testGetPlayStateShouldReturnFinishedWhenRateIsMissing {
    [self checkGetPlayStateShouldReturnPlayState:MediaControlPlayStateFinished
                           forMockResponseInFile:@"airplay_playbackinfo_finished"];
}

/// Tests that @c -getPlayStateWithSuccess:failure: infers the Unknown
/// play state from an empty playback-info response.
- (void)testGetPlayStateShouldReturnUnknownWhenResponseIsEmpty {
    [self checkGetPlayStateShouldReturnPlayState:MediaControlPlayStateUnknown
                                 forMockResponse:[NSDictionary dictionary]];
}

#pragma mark - Helpers

- (void)checkGetPlayStateShouldReturnPlayState:(MediaControlPlayState)expectedPlayState
                         forMockResponseInFile:(NSString *)responseFilename {
    NSString *responseFile = [[NSBundle bundleForClass:self.class] pathForResource:responseFilename
                                                                            ofType:@"json"];
    NSData *responseData = [NSData dataWithContentsOfFile:responseFile];
    NSError *error;
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:responseData
                                                             options:0
                                                               error:&error];
    XCTAssertNil(error, @"Couldn't read response");

    [self checkGetPlayStateShouldReturnPlayState:expectedPlayState
                                 forMockResponse:response];
}

- (void)checkGetPlayStateShouldReturnPlayState:(MediaControlPlayState)expectedPlayState
                               forMockResponse:(NSDictionary *)response {
    // Arrange
    id serviceMock = OCMClassMock([CNTAirPlayService class]);
    CNTAirPlayServiceHTTP *serviceHTTP = [[CNTAirPlayServiceHTTP alloc]
                                       initWithAirPlayService:serviceMock];

    id serviceCommandDelegateMock = OCMProtocolMock(@protocol(CNTServiceCommandDelegate));
    serviceHTTP.serviceCommandDelegate = serviceCommandDelegateMock;

    [OCMExpect([serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                           withPayload:OCMOCK_ANY
                                                 toURL:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        CNTServiceCommand *command = [invocation objectArgumentAtIndex:0];
        XCTAssertNotNil(command, @"Couldn't get the command argument");

        dispatch_async(dispatch_get_main_queue(), ^{
            command.callbackComplete(response);
        });
    }];

    XCTestExpectation *didReceivePlayState = [self expectationWithDescription:
                                              @"received playState"];

    // Act
    [serviceHTTP getPlayStateWithSuccess:^(MediaControlPlayState playState) {
        XCTAssertEqual(playState, expectedPlayState,
                       @"playState is incorrect");

        [didReceivePlayState fulfill];
    }
                                 failure:^(NSError *error) {
                                     XCTFail(@"Failure %@", error);
                                 }];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(serviceCommandDelegateMock);
                                 }];
}

@end
