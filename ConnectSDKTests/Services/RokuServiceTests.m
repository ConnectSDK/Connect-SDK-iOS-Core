//
//  RokuServiceTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-07-16.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "RokuService_Private.h"

#import "NSInvocation+ObjectGetter.h"

@interface RokuServiceTests : XCTestCase

@end

@implementation RokuServiceTests

- (void)testPlayVideoShouldSendNullEventURL {
    NSURL *url = [NSURL URLWithString:@"http://example.com/"];
    MediaInfo *videoInfo = [[MediaInfo alloc] initWithURL:url mimeType:@"video/mp4"];
    [self checkPlayMediaShouldSendNullEventURLWithMediaInfo:videoInfo];
}

- (void)testPlayAudioShouldSendNullEventURL {
    NSURL *url = [NSURL URLWithString:@"http://example.com/"];
    MediaInfo *videoInfo = [[MediaInfo alloc] initWithURL:url mimeType:@"audio/ogg"];
    [self checkPlayMediaShouldSendNullEventURLWithMediaInfo:videoInfo];
}

#pragma mark - Helpers

- (void)checkPlayMediaShouldSendNullEventURLWithMediaInfo:(MediaInfo *)mediaInfo {
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
        NSURLQueryItem *eventURLQueryItem = [[components.queryItems filteredArrayUsingPredicate:
                                              [NSPredicate predicateWithFormat:@"%K == %@", @"name", @"h"]] firstObject];
        XCTAssertEqualObjects(eventURLQueryItem.value, @"(null)",
                              @"The event URL should be null, because we don't support them now");

        [commandSentExpectation fulfill];
    }];

    [service playMediaWithMediaInfo:mediaInfo
                         shouldLoop:NO
                            success:nil
                            failure:nil];

    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout handler:nil];
}

@end
