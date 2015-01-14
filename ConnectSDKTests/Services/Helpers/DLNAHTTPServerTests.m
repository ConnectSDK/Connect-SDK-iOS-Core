//
//  DLNAHTTPServerTests.m
//  ConnectSDK
//
//  Created by Eugene Nikolskyi on 1/14/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "DLNAHTTPServer_Private.h"
#import "GCDWebServerDataRequest.h"

@interface EventInfo : NSObject

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSDictionary *query;

- (instancetype)initWithURL:(NSString *)url path:(NSString *)path andQuery:(NSDictionary *)query;

@end

@implementation EventInfo

- (instancetype)initWithURL:(NSString *)url path:(NSString *)path andQuery:(NSDictionary *)query {
    if (self = [super init]) {
        _url = url;
        _path = path;
        _query = query;
    }
    return self;
}

@end


/// Tests for the @c DLNAHTTPServer class.
@interface DLNAHTTPServerTests : XCTestCase

@end

@implementation DLNAHTTPServerTests

#pragma mark - Subscription Tests

/// Tests that the RenderingControl notification will only trigger the
/// RenderingControl success callback for sample Sonos event URLs.
- (void)testRenderingControlNotificationShouldTriggerRenderingControlSubscriptionOnly_Sonos {
    EventInfo *const kRenderingControlEventInfo = [[EventInfo alloc] initWithURL:@"/MediaRenderer/RenderingControl/Event"
                                                                            path:@"/MediaRenderer/RenderingControl/Event"
                                                                        andQuery:@{}];
    EventInfo *const kAVTransportEventInfo = [[EventInfo alloc] initWithURL:@"/MediaRenderer/AVTransport/Event"
                                                                       path:@"/MediaRenderer/AVTransport/Event"
                                                                   andQuery:@{}];
    [self checkRenderingControlNotificationShouldTriggerRenderingControlSubscriptionOnlyWithRenderingControlEventInfo:kRenderingControlEventInfo
                                                                                              andAVTransportEventInfo:kAVTransportEventInfo];
}

/// Tests that the RenderingControl notification will only trigger the
/// RenderingControl success callback for sample Xbox event URLs.
- (void)testRenderingControlNotificationShouldTriggerRenderingControlSubscriptionOnly_Xbox {
    EventInfo *const kRenderingControlEventInfo = [[EventInfo alloc] initWithURL:@"/upnphost/udhisapi.dll?event=uuid:0f4810a6-4fb4-4fdf-8acc-81e751e7ec8a+urn:upnp-org:serviceId:RenderingControl"
                                                                            path:@"/upnphost/udhisapi.dll"
                                                                        andQuery:@{@"event": @"uuid:0f4810a6-4fb4-4fdf-8acc-81e751e7ec8a+urn:upnp-org:serviceId:RenderingControl"}];
    EventInfo *const kAVTransportEventInfo = [[EventInfo alloc] initWithURL:@"/upnphost/udhisapi.dll?event=uuid:0f4810a6-4fb4-4fdf-8acc-81e751e7ec8a+urn:upnp-org:serviceId:AVTransport"
                                                                            path:@"/upnphost/udhisapi.dll"
                                                                        andQuery:@{@"event": @"uuid:0f4810a6-4fb4-4fdf-8acc-81e751e7ec8a+urn:upnp-org:serviceId:AVTransport"}];
    [self checkRenderingControlNotificationShouldTriggerRenderingControlSubscriptionOnlyWithRenderingControlEventInfo:kRenderingControlEventInfo
                                                                                              andAVTransportEventInfo:kAVTransportEventInfo];
}

- (void)checkRenderingControlNotificationShouldTriggerRenderingControlSubscriptionOnlyWithRenderingControlEventInfo:(EventInfo *)renderingControlEventInfo
                                                                                            andAVTransportEventInfo:(EventInfo *)avTransportEventInfo {
    // Arrange
    DLNAHTTPServer *server = [DLNAHTTPServer new];

    NSURL *const kSubscriptionBaseURL = [NSURL URLWithString:@"http://127.2"];

    XCTestExpectation *callbackIsCalledExpectation = [self expectationWithDescription:@"RenderingControl success callback is called"];
    ServiceSubscription *renderingControlSubscription = [[ServiceSubscription alloc] initWithDelegate:nil
                                                                                               target:[NSURL URLWithString:renderingControlEventInfo.url
                                                                                                             relativeToURL:kSubscriptionBaseURL]
                                                                                              payload:nil];
    [renderingControlSubscription addSuccess:^(id responseObject) {
        XCTAssertNotNil(responseObject);
        [callbackIsCalledExpectation fulfill];
    }];
    [renderingControlSubscription addFailure:^(NSError *error) {
        XCTFail(@"Should not be called");
    }];
    [server addSubscription:renderingControlSubscription];

    ServiceSubscription *avTransportSubscription = [[ServiceSubscription alloc] initWithDelegate:nil
                                                                                          target:[NSURL URLWithString:avTransportEventInfo.url
                                                                                                        relativeToURL:kSubscriptionBaseURL]
                                                                                         payload:nil];
    [avTransportSubscription addSuccess:^(id responseObject) {
        XCTFail(@"Must not be called");
    }];
    [avTransportSubscription addFailure:^(NSError *error) {
        XCTFail(@"Must not be called");
    }];
    [server addSubscription:avTransportSubscription];

    // Act
    NSURL *const kNotificationBaseURL = [NSURL URLWithString:@"http://127.1"];
    NSData *const kNotificationData = [@"<e:propertyset xmlns:e='urn:schemas-upnp-org:event-1-0'><e:property><LastChange xmlns:dt='urn:schemas-microsoft-com:datatypes' dt:dt='string'>&lt;Event xmlns='urn:schemas-upnp-org:metadata-1-0/RCS/'&gt;&lt;InstanceID val='0'&gt;&lt;Mute channel='Master' val='0'/&gt;&lt;Volume channel='Master' val='3'/&gt;&lt;PresetNameList val='FactoryDefaults'/&gt;&lt;/InstanceID&gt;&lt;/Event&gt;</LastChange></e:property></e:propertyset>" dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *kRenderingControlNotificationURL = [NSURL URLWithString:renderingControlEventInfo.url
                                                     relativeToURL:kNotificationBaseURL];

    id renderingControlNotificationMock = OCMClassMock(GCDWebServerDataRequest.class);
    OCMStub([renderingControlNotificationMock data]).andReturn(kNotificationData);
    OCMStub([renderingControlNotificationMock path]).andReturn(renderingControlEventInfo.path);
    OCMStub([renderingControlNotificationMock query]).andReturn(renderingControlEventInfo.query);
    OCMStub([renderingControlNotificationMock URL]).andReturn(kRenderingControlNotificationURL);
    [server processRequest:renderingControlNotificationMock];

    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:^(NSError *error) {
                                     XCTAssertNil(error);
                                 }];
}

@end
