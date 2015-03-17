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
#import <OHHTTPStubs/OHHTTPStubs.h>
#import "NSInvocation+ObjectGetter.h"

#import "CTXMLReader.h"
#import "DLNAService_Private.h"
#import "ConnectError.h"
#import "NSDictionary+KeyPredicateSearch.h"

static NSString *const kPlatformXbox = @"xbox";
static NSString *const kPlatformSonos = @"sonos";

static NSString *const kAVTransportNamespace = @"urn:schemas-upnp-org:service:AVTransport:1";
static NSString *const kRenderingControlNamespace = @"urn:schemas-upnp-org:service:RenderingControl:1";


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

#pragma mark - Request Generation Tests

static NSString *const kDefaultTitle = @"Hello, <World> &]]> \"others'\\ ура ξ中]]>…";
static NSString *const kDefaultDescription = @"<Description> &\"'";
static NSString *const kDefaultURL = @"http://example.com/media.ogg";
static NSString *const kDefaultAlbumArtURL = @"http://example.com/media.png";

/// Tests that @c -playMediaWithMediaInfo:shouldLoop:success:failure: creates a
/// proper and valid SetAVTransportURI XML request.
- (void)testPlayMediaShouldCreateProperSetAVTransportURIXML {
    [self checkPlayMediaShouldCreateProperSetAVTransportURIXMLWithTitle:kDefaultTitle
                                                            description:kDefaultDescription
                                                                    url:kDefaultURL
                                                         andAlbumArtURL:kDefaultAlbumArtURL];
}

/// Tests that @c -playMediaWithMediaInfo:shouldLoop:success:failure: creates a
/// proper and valid SetAVTransportURI XML request without title.
- (void)testPlayMediaShouldCreateProperSetAVTransportURIXMLWithoutTitle {
    [self checkPlayMediaShouldCreateProperSetAVTransportURIXMLWithTitle:nil
                                                            description:kDefaultDescription
                                                                    url:kDefaultURL
                                                         andAlbumArtURL:kDefaultAlbumArtURL];
}

/// Tests that @c -playMediaWithMediaInfo:shouldLoop:success:failure: creates a
/// proper and valid SetAVTransportURI XML request without description.
- (void)testPlayMediaShouldCreateProperSetAVTransportURIXMLWithoutDescription {
    [self checkPlayMediaShouldCreateProperSetAVTransportURIXMLWithTitle:kDefaultTitle
                                                            description:nil
                                                                    url:kDefaultURL
                                                         andAlbumArtURL:kDefaultAlbumArtURL];
}

/// Tests that @c -playMediaWithMediaInfo:shouldLoop:success:failure: creates a
/// proper and valid SetAVTransportURI XML request without URL.
- (void)testPlayMediaShouldCreateProperSetAVTransportURIXMLWithoutURL {
    [self checkPlayMediaShouldCreateProperSetAVTransportURIXMLWithTitle:kDefaultTitle
                                                            description:kDefaultDescription
                                                                    url:nil
                                                         andAlbumArtURL:kDefaultAlbumArtURL];
}

/// Tests that @c -playMediaWithMediaInfo:shouldLoop:success:failure: creates a
/// proper and valid SetAVTransportURI XML request without album art URL.
- (void)testPlayMediaShouldCreateProperSetAVTransportURIXMLWithoutAlbumArtURL {
    [self checkPlayMediaShouldCreateProperSetAVTransportURIXMLWithTitle:kDefaultTitle
                                                            description:kDefaultDescription
                                                                    url:kDefaultURL
                                                         andAlbumArtURL:nil];
}

/// Tests that @c -playWithSuccess:failure: creates a proper and valid Play XML
/// request.
- (void)testPlayShouldCreateProperPlayXML {
    [self setupSendCommandTestWithName:@"Play"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service playWithSuccess:^(id responseObject) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Speed.text"], @"1", @"Speed must equal 1");
                           }];
}

/// Tests that @c -pauseWithSuccess:failure: creates a proper and valid Pause
/// XML request.
- (void)testPauseShouldCreateProperPauseXML {
    [self setupSendCommandTestWithName:@"Pause"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service pauseWithSuccess:^(id responseObject) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:nil];
}

/// Tests that @c -stopWithSuccess:failure: creates a proper and valid Stop XML
/// request.
- (void)testStopShouldCreateProperStopXML {
    [self setupSendCommandTestWithName:@"Stop"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service stopWithSuccess:^(id responseObject) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:nil];
}

/// Tests that @c -seek:success:failure: creates a proper and valid Seek XML
/// request.
- (void)testSeekShouldCreateProperSeekXML {
    [self setupSendCommandTestWithName:@"Seek"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service seek:(1 * 60 * 60) + (45 * 60) + 33
                                          success:^(id responseObject) {
                                              XCTFail(@"success?");
                                          } failure:^(NSError *error) {
                                              XCTFail(@"fail? %@", error);
                                          }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Target.text"],
                                                     @"01:45:33", @"Seek position is incorrect");
                               XCTAssertEqualObjects([request valueForKeyPath:@"Unit.text"],
                                                     @"REL_TIME", @"Unit is incorrect");
                           }];
}

/// Tests that @c -getPlayStateWithSuccess:failure: creates a proper and valid
/// GetTransportInfo XML request.
- (void)testGetPlayStateShouldCreateProperGetTransportInfoXML {
    [self setupSendCommandTestWithName:@"GetTransportInfo"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service getPlayStateWithSuccess:^(MediaControlPlayState playState) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:nil];
}

/// Tests that @c -getPositionWithSuccess:failure: creates a proper and valid
/// GetPositionInfo XML request.
- (void)testGetPositionInfoShouldCreateProperGetPositionInfoXML {
    [self setupSendCommandTestWithName:@"GetPositionInfo"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service getPositionWithSuccess:^(NSTimeInterval position) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:nil];
}

/// Tests that @c -getVolumeWithSuccess:failure: creates a proper and valid
/// GetVolume XML request.
- (void)testGetVolumeShouldCreateProperGetVolumeXML {
    [self setupSendCommandTestWithName:@"GetVolume"
                             namespace:kRenderingControlNamespace
                           actionBlock:^{
                               [self.service getVolumeWithSuccess:^(float volume) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Channel.text"],
                                                     @"Master", @"Channel must be Master");
                           }];
}

/// Tests that @c -setVolume:success:failure: creates a proper and valid
/// SetVolume XML request.
- (void)testSetVolumeShouldCreateProperSetVolumeXML {
    [self setupSendCommandTestWithName:@"SetVolume"
                             namespace:kRenderingControlNamespace
                           actionBlock:^{
                               [self.service setVolume:0.99
                                               success:^(id responseObject) {
                                                   XCTFail(@"success?");
                                               } failure:^(NSError *error) {
                                                   XCTFail(@"fail? %@", error);
                                               }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Channel.text"],
                                                     @"Master", @"Channel must be Master");
                               XCTAssertEqualObjects([request valueForKeyPath:@"DesiredVolume.text"],
                                                     @"99", @"Volume is incorrect");
                           }];
}

/// Tests that @c -getMuteWithSuccess:failure: creates a proper and valid
/// GetMute XML request.
- (void)testGetMuteShouldCreateProperGetMuteXML {
    [self setupSendCommandTestWithName:@"GetMute"
                             namespace:kRenderingControlNamespace
                           actionBlock:^{
                               [self.service getMuteWithSuccess:^(BOOL mute) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Channel.text"],
                                                     @"Master", @"Channel must be Master");
                           }];
}

/// Tests that @c -setMute:success:failure: creates a proper and valid
/// SetMute XML request.
- (void)testSetMuteShouldCreateProperSetMuteXML {
    [self setupSendCommandTestWithName:@"SetMute"
                             namespace:kRenderingControlNamespace
                           actionBlock:^{
                               [self.service setMute:YES
                                             success:^(id responseObject) {
                                                 XCTFail(@"success?");
                                             } failure:^(NSError *error) {
                                                 XCTFail(@"fail? %@", error);
                                             }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Channel.text"],
                                                     @"Master", @"Channel must be Master");
                               XCTAssertEqualObjects([request valueForKeyPath:@"DesiredMute.text"],
                                                     @"1", @"DesiredMute is incorrect");
                           }];
}

/// Tests that @c -playNextWithSuccess:failure: creates a proper and valid Next
/// XML request.
- (void)testPlayNextShouldCreateProperNextXML {
    [self setupSendCommandTestWithName:@"Next"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service playNextWithSuccess:^(id responseObject) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:nil];
}

/// Tests that @c -playPreviousWithSuccess:failure: creates a proper and valid
/// Previous XML request.
- (void)testPlayPreviousShouldCreateProperPreviousXML {
    [self setupSendCommandTestWithName:@"Previous"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service playPreviousWithSuccess:^(id responseObject) {
                                   XCTFail(@"success?");
                               } failure:^(NSError *error) {
                                   XCTFail(@"fail? %@", error);
                               }];
                           } andVerificationBlock:nil];
}

/// Tests that @c -jumpToTrackWithIndex:success:failure: creates a proper and
/// valid Seek XML request.
- (void)testJumpToTrackShouldCreateProperSeekXML {
    [self setupSendCommandTestWithName:@"Seek"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               [self.service jumpToTrackWithIndex:0
                                                          success:^(id responseObject) {
                                                              XCTFail(@"success?");
                                                          } failure:^(NSError *error) {
                                                              XCTFail(@"fail? %@", error);
                                                          }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"Target.text"],
                                                     @"1", @"Track number is incorrect");
                               XCTAssertEqualObjects([request valueForKeyPath:@"Unit.text"],
                                                     @"TRACK_NR", @"Unit is incorrect");
                           }];
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

/// Tests that @c DLNAService parses a UPnP error from a sample Xbox response
/// properly.
- (void)testUPnPErrorShouldBeParsedProperly_Xbox {
    [self checkUPnPErrorShouldBeParsedProperlyWithSamplePlatform:kPlatformXbox
                                             andErrorDescription:@"Invalid Action"];
}

/// Tests that @c DLNAService parses a UPnP error from a sample Sonos response
/// properly.
- (void)testUPnPErrorShouldBeParsedProperly_Sonos {
    [self checkUPnPErrorShouldBeParsedProperlyWithSamplePlatform:kPlatformSonos
                                             andErrorDescription:nil];
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

- (void)checkUPnPErrorShouldBeParsedProperlyWithSamplePlatform:(NSString *)platform
                                           andErrorDescription:(NSString *)errorDescription {
    // Arrange
    self.service.serviceCommandDelegate = nil;
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    }
                        withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
                            NSString *filename = [NSString stringWithFormat:@"upnperror_response_%@.xml", platform];
                            return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(filename, nil)
                                                                    statusCode:500
                                                                       headers:nil];
                        }];

    XCTestExpectation *failExpectation = [self expectationWithDescription:@"The failure: block should be called"];

    // Act
    [self.service getMuteWithSuccess:^(BOOL mute) {
        XCTFail(@"Should not succeed here");
    }
                             failure:^(NSError *error) {
                                 XCTAssertEqualObjects(error.domain, ConnectErrorDomain, @"The error domain is incorrect");
                                 XCTAssertEqual(error.code, ConnectStatusCodeTvError, @"The error code is incorrect");
                                 if (errorDescription) {
                                     XCTAssertNotEqual(NSNotFound,
                                                       [error.localizedDescription rangeOfString:errorDescription].location,
                                                       @"The error description is incorrect");
                                 } else {
                                     XCTAssertGreaterThan(error.localizedDescription.length,
                                                          0, @"The error description must not be empty");
                                 }
                                 [failExpectation fulfill];
                             }];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                 }];
    [OHHTTPStubs removeAllStubs];
}

- (void)callCommandCallbackFromInvocation:(NSInvocation *)invocation
                      andResponseFilename:(NSString *)filename {
    __unsafe_unretained ServiceCommand *tmp;
    [invocation getArgument:&tmp atIndex:2];
    ServiceCommand *command = tmp;
    XCTAssertNotNil(command, @"Couldn't get the command argument");

    NSData *xmlData = [NSData dataWithContentsOfFile:
                       OHPathForFileInBundle([filename stringByAppendingPathExtension:@"xml"], nil)];
    XCTAssertNotNil(xmlData, @"Response data is unavailable");

    NSError *error;
    NSDictionary *dict = [CTXMLReader dictionaryForXMLData:xmlData
                                                     error:&error];
    XCTAssertNil(error, @"XML parsing error: %@", error);

    dispatch_async(dispatch_get_main_queue(), ^{
        command.callbackComplete(dict);
    });
}

- (void)setupSendCommandTestWithName:(NSString *)commandName
                           namespace:(NSString *)namespace
                         actionBlock:(void (^)())actionBlock
                andVerificationBlock:(void (^)(NSDictionary *request))checkBlock {
    // Arrange
    XCTestExpectation *commandIsSent = [self expectationWithDescription:
                                        [NSString stringWithFormat:@"%@ command is sent", commandName]];

    [OCMExpect([self.serviceCommandDelegateMock sendCommand:OCMOCK_NOTNIL
                                                withPayload:OCMOCK_NOTNIL
                                                      toURL:OCMOCK_ANY]) andDo:^(NSInvocation *inv) {
        NSDictionary *payload = [inv objectArgumentAtIndex:1];
        NSString *xmlString = payload[kDataFieldName];
        XCTAssertNotNil(xmlString, @"XML request not found");

        NSError *error = nil;
        NSDictionary *dict = [CTXMLReader dictionaryForXMLString:xmlString
                                                           error:&error];
        XCTAssertNil(error, @"XML parsing error");
        XCTAssertNotNil(dict, @"Couldn't parse XML");

        NSDictionary *envelope = [dict objectForKeyEndingWithString:@":Envelope"];
        XCTAssertNotNil(envelope, @"Envelope tag must be present");
        XCTAssertEqualObjects(envelope[@"xmlns:u"], namespace, @"Namespace is incorrect");
        NSDictionary *body = [envelope objectForKeyEndingWithString:@":Body"];
        XCTAssertNotNil(body, @"Body tag must be present");
        NSDictionary *request = [body objectForKeyEndingWithString:[@":" stringByAppendingString:commandName]];
        XCTAssertNotNil(request, @"%@ tag must be present", commandName);

        XCTAssertNotNil(request[@"InstanceID"], @"InstanceID must be present");

        // any extra verification required?
        if (checkBlock) {
            checkBlock(request);
        }

        [commandIsSent fulfill];
    }];

    // Act
    actionBlock();

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                     OCMVerifyAll(self.serviceCommandDelegateMock);
                                 }];
}

- (void)checkPlayMediaShouldCreateProperSetAVTransportURIXMLWithTitle:(NSString *)sampleTitle
                                                          description:(NSString *)sampleDescription
                                                                  url:(NSString *)sampleURL
                                                       andAlbumArtURL:(NSString *)sampleAlbumArtURL {
    NSString *sampleMimeType = @"audio/ogg";

    [self setupSendCommandTestWithName:@"SetAVTransportURI"
                             namespace:kAVTransportNamespace
                           actionBlock:^{
                               MediaInfo *mediaInfo = [[MediaInfo alloc] initWithURL:[NSURL URLWithString:sampleURL]
                                                                            mimeType:sampleMimeType];
                               mediaInfo.title = sampleTitle;
                               mediaInfo.description = sampleDescription;
                               mediaInfo.images = @[[[ImageInfo alloc] initWithURL:[NSURL URLWithString:sampleAlbumArtURL]
                                                                              type:ImageTypeAlbumArt]];

                               [self.service playMediaWithMediaInfo:mediaInfo
                                                         shouldLoop:NO
                                                            success:^(MediaLaunchObject *mediaLanchObject) {
                                                                XCTFail(@"success?");
                                                            } failure:^(NSError *error) {
                                                                XCTFail(@"fail? %@", error);
                                                            }];
                           } andVerificationBlock:^(NSDictionary *request) {
                               XCTAssertEqualObjects([request valueForKeyPath:@"CurrentURI.text"], sampleURL, @"CurrentURI must match");

                               NSString *metadataString = [request valueForKeyPath:@"CurrentURIMetaData.text"];
                               XCTAssertNotNil(metadataString, @"CurrentURIMetaData must be present");

                               NSError *error = nil;
                               NSDictionary *metadata = [CTXMLReader dictionaryForXMLString:metadataString
                                                                                      error:&error];
                               XCTAssertNil(error, @"Metadata XML parsing error");
                               XCTAssertNotNil(metadata, @"Couldn't parse metadata XML");

                               NSDictionary *didl = metadata[@"DIDL-Lite"];
                               XCTAssertNotNil(didl, @"DIDL-Lite tag must be present");
                               NSDictionary *item = didl[@"item"];
                               XCTAssertNotNil(item, @"item tag must be present");

                               NSString *title = [item objectForKeyEndingWithString:@":title"][@"text"];
                               XCTAssertEqualObjects(title, sampleTitle, @"Title must match");

                               NSString *description = [item objectForKeyEndingWithString:@":description"][@"text"];
                               XCTAssertEqualObjects(description, sampleDescription, @"Description must match");

                               NSDictionary *res = item[@"res"];
                               XCTAssertEqualObjects(res[@"text"], sampleURL, @"res URL must match");
                               XCTAssertNotEqual([res[@"protocolInfo"] rangeOfString:sampleMimeType].location, NSNotFound, @"mimeType must be in protocolInfo");

                               NSString *albumArtURI = [item objectForKeyEndingWithString:@":albumArtURI"][@"text"];
                               XCTAssertEqualObjects(albumArtURI, sampleAlbumArtURL, @"albumArtURI must match");

                               NSString *itemClass = [item objectForKeyEndingWithString:@":class"][@"text"];
                               XCTAssertEqualObjects(itemClass, @"object.item.audioItem", @"class must be audioItem");
                           }];
}

@end
