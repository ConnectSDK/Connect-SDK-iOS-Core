//
//  RokuServiceTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-07-16.
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

#import "RokuService_Private.h"

#import "NSInvocation+ObjectGetter.h"

@interface RokuServiceTests : XCTestCase

@end

@implementation RokuServiceTests

- (void)testPlayVideoShouldNotSendEventURL {
    NSURL *url = [NSURL URLWithString:@"http://example.com/"];
    MediaInfo *videoInfo = [[MediaInfo alloc] initWithURL:url mimeType:@"video/mp4"];
    [self checkPlayMediaBlockShouldNotSendEventURL:^(RokuService *service) {
        [service playMediaWithMediaInfo:videoInfo
                             shouldLoop:NO
                                success:nil
                                failure:nil];
    }];
}

- (void)testPlayAudioShouldNotSendEventURL {
    NSURL *url = [NSURL URLWithString:@"http://example.com/"];
    MediaInfo *audioInfo = [[MediaInfo alloc] initWithURL:url mimeType:@"audio/ogg"];
    [self checkPlayMediaBlockShouldNotSendEventURL:^(RokuService *service) {
        [service playMediaWithMediaInfo:audioInfo
                             shouldLoop:NO
                                success:nil
                                failure:nil];
    }];
}

- (void)testDisplayImageShouldNotSendEventURL {
    NSURL *url = [NSURL URLWithString:@"http://example.com/"];
    MediaInfo *imageInfo = [[MediaInfo alloc] initWithURL:url mimeType:@"image/png"];
    [self checkPlayMediaBlockShouldNotSendEventURL:^(RokuService *service) {
        [service displayImageWithMediaInfo:imageInfo
                                   success:nil
                                   failure:nil];
    }];
}

#pragma mark - Helpers

- (void)checkPlayMediaBlockShouldNotSendEventURL:(void (^)(RokuService *service))testBlock {
    id serviceCommandDelegateMock = OCMProtocolMock(@protocol(ServiceCommandDelegate));
    RokuService *service = [RokuService new];
    service.serviceCommandDelegate = serviceCommandDelegateMock;

    id serviceDescriptionMock = OCMClassMock([ServiceDescription class]);
    [OCMStub([serviceDescriptionMock commandURL]) andReturn:[NSURL URLWithString:@"http://42"]];
    service.serviceDescription = serviceDescriptionMock;

    XCTestExpectation *commandSentExpectation = [self expectationWithDescription:@"command is sent"];

    [OCMExpect([serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                           withPayload:OCMOCK_ANY
                                                 toURL:OCMOCK_NOTNIL]) andDo:^(NSInvocation *inv) {
        NSURL *url = [inv objectArgumentAtIndex:2];
        NSURLComponents *components = [NSURLComponents componentsWithURL:url
                                                 resolvingAgainstBaseURL:NO];
        NSArray *eventURLQueryItems = [components.queryItems filteredArrayUsingPredicate:
                                       [NSPredicate predicateWithFormat:@"%K == %@", @"name", @"h"]];
        XCTAssertEqual(eventURLQueryItems.count, 0,
                       @"The event URL should not be sent in the request");

        [commandSentExpectation fulfill];
    }];

    testBlock(service);

    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout handler:nil];
}

@end
