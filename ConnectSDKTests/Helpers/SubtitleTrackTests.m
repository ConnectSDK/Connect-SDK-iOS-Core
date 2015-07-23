//
//  SubtitleTrackTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 2015-07-14.
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

#import "SubtitleTrack.h"

@interface SubtitleTrackTests : XCTestCase

@property (nonatomic, strong) NSURL *url;

@end

@implementation SubtitleTrackTests

- (void)setUp {
    [super setUp];

    self.url = [NSURL URLWithString:@"http://example.com/"];
}

#pragma mark - Init Tests

- (void)testDefaultInitShouldThrowException {
    XCTAssertThrowsSpecificNamed([SubtitleTrack new],
                                 NSException,
                                 NSInternalInconsistencyException,
                                 @"Default initializer is not permitted");
}

- (void)testTrackConstructorShouldNotAcceptNilURL {
    NSURL *nilUrl = [NSURL URLWithString:nil];
    XCTAssertThrowsSpecificNamed([SubtitleTrack trackWithURL:nilUrl],
                                 NSException,
                                 NSInternalInconsistencyException);
}

- (void)testTrackConstructorWithBuilderShouldNotAcceptNilURL {
    NSURL *nilUrl = [NSURL URLWithString:nil];
    XCTAssertThrowsSpecificNamed([SubtitleTrack trackWithURL:nilUrl
                                                    andBlock:^(SubtitleTrackBuilder *_) {}],
                                 NSException,
                                 NSInternalInconsistencyException);
}

- (void)testTrackConstructorShouldSetURL {
    SubtitleTrack *track = [SubtitleTrack trackWithURL:self.url];
    XCTAssertEqualObjects(track.url, self.url);
}

- (void)testTrackConstructorShouldLeaveOptionalPropertiesNil {
    SubtitleTrack *track = [SubtitleTrack trackWithURL:self.url];
    XCTAssertNil(track.mimeType);
    XCTAssertNil(track.language);
    XCTAssertNil(track.label);
}

- (void)testBuilderShouldSetProperties {
    SubtitleTrack *track = [SubtitleTrack trackWithURL:self.url
                                              andBlock:^(SubtitleTrackBuilder *builder) {
                                                  builder.mimeType = @"text/vtt";
                                                  builder.language = @"en";
                                                  builder.label = @"Test";
                                            }];

    XCTAssertEqualObjects(track.url, self.url);
    XCTAssertEqualObjects(track.mimeType, @"text/vtt");
    XCTAssertEqualObjects(track.language, @"en");
    XCTAssertEqualObjects(track.label, @"Test");
}

@end
