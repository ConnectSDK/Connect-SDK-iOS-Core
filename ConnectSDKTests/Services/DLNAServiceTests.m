//
//  DLNAServiceTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/13/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import "CTXMLReader.h"
#import "DLNAService_Private.h"

static const CGFloat kDefaultAsyncTestTimeout = 0.5f;

static NSString *const kPlatformXbox = @"xbox";
static NSString *const kPlatformSonos = @"sonos";

/// Tests for the @c DLNAService class.
@interface DLNAServiceTests : XCTestCase

@property (nonatomic, strong) id serviceCommandDelegateMock;
@property (nonatomic, strong) DLNAService *service;

@end

@implementation DLNAServiceTests

- (void)setUp {
    [super setUp];
    self.serviceCommandDelegateMock = OCMProtocolMock(@protocol(ServiceCommandDelegate));
    self.service = [DLNAService new];
    self.service.serviceCommandDelegate = self.serviceCommandDelegateMock;
}

- (void)tearDown {
    self.service = nil;
    self.serviceCommandDelegateMock = nil;
    [super tearDown];
}

#pragma mark - Response Parsing Tests

/// Tests that @c -getPositionWithSuccess:failure: parses the position time from
/// a sample Xbox response properly.
- (void)testGetPositionShouldParseTimeProperly_Xbox {
    [self checkGetPositionShouldParseTimeProperlyWithSamplePlatform:kPlatformXbox];
}

/// Tests that @c -getPositionWithSuccess:failure: parses the position time from
/// a sample Sonos response properly.
- (void)testGetPositionShouldParseTimeProperly_Sonos {
    [self checkGetPositionShouldParseTimeProperlyWithSamplePlatform:kPlatformSonos];
}

/// Tests that @c -getDurationWithSuccess:failure: parses the duration time from
/// a sample Xbox response properly.
- (void)testGetDurationShouldParseTimeProperly_Xbox {
    [self checkGetDurationShouldParseTimeProperlyWithSamplePlatform:kPlatformXbox];
}

/// Tests that @c -getDurationWithSuccess:failure: parses the duration time from
/// a sample Sonos response properly.
- (void)testGetDurationShouldParseTimeProperly_Sonos {
    [self checkGetDurationShouldParseTimeProperlyWithSamplePlatform:kPlatformSonos];
}

/// Tests that @c -getMediaMetaDataWithSuccess:failure: parses the metadata from
/// a sample Xbox response properly.
- (void)testGetMediaMetadataShouldParseTimeProperly_Xbox {
    NSDictionary *expectedMetadata = @{@"title": @"Sintel Character Design",
                                       @"subtitle": @"Blender Open Movie Project",
                                       @"iconURL": @"http://ec2-54-201-108-205.us-west-2.compute.amazonaws.com/samples/media/videoIcon.jpg"};
    [self checkGetMediaMetadataShouldParseTimeProperlyWithSamplePlatform:kPlatformXbox
                                                     andExpectedMetadata:expectedMetadata];
}

/// Tests that @c -getMediaMetaDataWithSuccess:failure: parses the metadata from
/// a sample Sonos response properly.
- (void)testGetMediaMetadataShouldParseTimeProperly_Sonos {
    NSDictionary *expectedMetadata = @{@"title": @"Sintel Trailer",
                                       @"subtitle": @"Durian Open Movie Team"};
    [self checkGetMediaMetadataShouldParseTimeProperlyWithSamplePlatform:kPlatformSonos
                                                     andExpectedMetadata:expectedMetadata];
}

/// Tests that @c -getPlayStateWithSuccess:failure: parses the play state from
/// a sample Xbox response properly.
- (void)testGetPlayStateShouldParsePlayStateProperly_Xbox {
    [self checkGetPlayStateShouldParsePlayStateProperlyWithSamplePlatform:kPlatformXbox];
}

/// Tests that @c -getPlayStateWithSuccess:failure: parses the play state from
/// a sample Sonos response properly.
- (void)testGetPlayStateShouldParsePlayStateProperly_Sonos {
    [self checkGetPlayStateShouldParsePlayStateProperlyWithSamplePlatform:kPlatformSonos];
}

/// Tests that @c -getVolumeWithSuccess:failure: parses the volume from a sample
/// Xbox response properly.
- (void)testGetVolumeShouldParseVolumeProperly_Xbox {
    [self checkGetVolumeShouldParseVolumeProperlyWithSamplePlatform:kPlatformXbox];
}

/// Tests that @c -getVolumeWithSuccess:failure: parses the volume from a sample
/// Sonos response properly.
- (void)testGetVolumeShouldParseVolumeProperly_Sonos {
    [self checkGetVolumeShouldParseVolumeProperlyWithSamplePlatform:kPlatformSonos];
}

/// Tests that @c -getMuteWithSuccess:failure: parses the mute from a sample
/// Xbox response properly.
- (void)testGetMuteShouldParseMuteProperly_Xbox {
    [self checkGetMuteShouldParseMuteProperlyWithSamplePlatform:kPlatformXbox];
}

/// Tests that @c -getMuteWithSuccess:failure: parses the mute from a sample
/// Sonos response properly.
- (void)testGetMuteShouldParseMuteProperly_Sonos {
    [self checkGetMuteShouldParseMuteProperlyWithSamplePlatform:kPlatformSonos];
}

#pragma mark - Helpers

- (void)checkGetPositionShouldParseTimeProperlyWithSamplePlatform:(NSString *)platform {
    // Arrange
    OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                               withPayload:OCMOCK_NOTNIL
                                                     toURL:OCMOCK_ANY]).andDo((^(NSInvocation *inv) {
        [self callCommandCallbackFromInvocation:inv
                            andResponseFilename:[NSString stringWithFormat:@"getpositioninfo_response_%@", platform]];
    }));

    XCTestExpectation *getPositionSuccessExpectation = [self expectationWithDescription:@"The position time is parsed properly"];

    // Act
    [self.service getPositionWithSuccess:^(NSTimeInterval position) {
        XCTAssertEqualWithAccuracy(position, 66.0, 0.001,
                                   @"The position time is incorrect");
        [getPositionSuccessExpectation fulfill];
    }
                                 failure:^(NSError *error) {
                                     XCTFail(@"Should not be a failure: %@", error);
                                 }];
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)checkGetDurationShouldParseTimeProperlyWithSamplePlatform:(NSString *)platform {
    // Arrange
    OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                               withPayload:OCMOCK_NOTNIL
                                                     toURL:OCMOCK_ANY]).andDo((^(NSInvocation *inv) {
        [self callCommandCallbackFromInvocation:inv
                            andResponseFilename:[NSString stringWithFormat:@"getpositioninfo_response_%@", platform]];
    }));

    XCTestExpectation *getDurationSuccessExpectation = [self expectationWithDescription:@"The duration is parsed properly"];

    // Act
    [self.service getDurationWithSuccess:^(NSTimeInterval position) {
        XCTAssertEqualWithAccuracy(position, (8.0*60 + 52), 0.001,
                                   @"The duration is incorrect");
        [getDurationSuccessExpectation fulfill];
    }
                                 failure:^(NSError *error) {
                                     XCTFail(@"Should not be a failure: %@", error);
                                 }];
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)checkGetMediaMetadataShouldParseTimeProperlyWithSamplePlatform:(NSString *)platform
                                                   andExpectedMetadata:(NSDictionary *)expectedMetadata {
    // Arrange
    OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                               withPayload:OCMOCK_NOTNIL
                                                     toURL:OCMOCK_ANY]).andDo((^(NSInvocation *inv) {
        [self callCommandCallbackFromInvocation:inv
                            andResponseFilename:[NSString stringWithFormat:@"getpositioninfo_response_%@", platform]];
    }));

    XCTestExpectation *getMetadataSuccessExpectation = [self expectationWithDescription:@"The metadata is parsed properly"];

    // Act
    [self.service getMediaMetaDataWithSuccess:^(NSDictionary *metadata) {
        XCTAssertEqualObjects(metadata, expectedMetadata, @"The metadata is incorrect");
        [getMetadataSuccessExpectation fulfill];
    }
                                 failure:^(NSError *error) {
                                     XCTFail(@"Should not be a failure: %@", error);
                                 }];
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)checkGetPlayStateShouldParsePlayStateProperlyWithSamplePlatform:(NSString *)platform {
    // Arrange
    OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                               withPayload:OCMOCK_NOTNIL
                                                     toURL:OCMOCK_ANY]).andDo((^(NSInvocation *inv) {
        [self callCommandCallbackFromInvocation:inv
                            andResponseFilename:[NSString stringWithFormat:@"gettransportinfo_response_%@", platform]];
    }));

    XCTestExpectation *getPlayStateSuccessExpectation = [self expectationWithDescription:@"The play state is parsed properly"];

    // Act
    [self.service getPlayStateWithSuccess:^(MediaControlPlayState playState) {
        XCTAssertEqual(playState, MediaControlPlayStatePlaying,
                       @"The play state is incorrect");
        [getPlayStateSuccessExpectation fulfill];
    }
                                 failure:^(NSError *error) {
                                     XCTFail(@"Should not be a failure: %@", error);
                                 }];
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)checkGetVolumeShouldParseVolumeProperlyWithSamplePlatform:(NSString *)platform {
    // Arrange
    OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                               withPayload:OCMOCK_NOTNIL
                                                     toURL:OCMOCK_ANY]).andDo((^(NSInvocation *inv) {
        [self callCommandCallbackFromInvocation:inv
                            andResponseFilename:[NSString stringWithFormat:@"getvolume_response_%@", platform]];
    }));

    XCTestExpectation *getVolumeSuccessExpectation = [self expectationWithDescription:@"The volume is parsed properly"];

    // Act
    [self.service getVolumeWithSuccess:^(float volume) {
        XCTAssertEqualWithAccuracy(volume, 0.14f, 0.0001, @"The volume is incorrect");
        [getVolumeSuccessExpectation fulfill];
    }
                                 failure:^(NSError *error) {
                                     XCTFail(@"Should not be a failure: %@", error);
                                 }];
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)checkGetMuteShouldParseMuteProperlyWithSamplePlatform:(NSString *)platform {
    // Arrange
    OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                               withPayload:OCMOCK_NOTNIL
                                                     toURL:OCMOCK_ANY]).andDo((^(NSInvocation *inv) {
        [self callCommandCallbackFromInvocation:inv
                            andResponseFilename:[NSString stringWithFormat:@"getmute_response_%@", platform]];
    }));

    XCTestExpectation *getMuteSuccessExpectation = [self expectationWithDescription:@"The mute is parsed properly"];

    // Act
    [self.service getMuteWithSuccess:^(BOOL mute) {
        XCTAssertTrue(mute, @"The mute value is incorrect");
        [getMuteSuccessExpectation fulfill];
    }
                                 failure:^(NSError *error) {
                                     XCTFail(@"Should not be a failure: %@", error);
                                 }];
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)callCommandCallbackFromInvocation:(NSInvocation *)invocation
                      andResponseFilename:(NSString *)filename {
    __unsafe_unretained ServiceCommand *tmp;
    [invocation getArgument:&tmp atIndex:2];
    ServiceCommand *command = tmp;
    XCTAssertNotNil(command, @"Couldn't get the command argument");

    NSData *xmlData = [NSData dataWithContentsOfFile:[[NSBundle bundleForClass:self.class]
                                                      pathForResource:filename ofType:@"xml"]];
    XCTAssertNotNil(xmlData, @"Response data is unavailable");

    NSError *error;
    NSDictionary *dict = [CTXMLReader dictionaryForXMLData:xmlData
                                                     error:&error];
    XCTAssertNil(error, @"XML parsing error: %@", error);

    dispatch_async(dispatch_get_main_queue(), ^{
        command.callbackComplete(dict);
    });
}

@end
