//
//  WebOSWebAppSessionTests.m
//  ConnectSDK
//
//  Created by Ibrahim Adnan on 6/18/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "WebOSWebAppSession.h"
#import "WebOSTVServiceSocketClient.h"

@interface WebOSWebAppSessionTests : XCTestCase

@end

@implementation WebOSWebAppSessionTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFailureBlockIsCalledinPlayStateSubscriptionWhenMediaPlayerThrowsError{
    WebOSWebAppSession *session = [WebOSWebAppSession new];
    session.fullAppId = @"com.lgsmartplatform.redirect.MediaPlayer";
    // Arrange
    XCTestExpectation *failureBlockCalledExpectation = [self expectationWithDescription:@"Failure block is called"];
    [session subscribePlayStateWithSuccess:nil failure:^(NSError *error) {
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
    

    // Action
    [session socket:OCMOCK_ANY didReceiveMessage:errorPayload];
   
    // Assert
    [self waitForExpectationsWithTimeout:kDefaultAsyncTestTimeout
                                 handler:nil];
}

@end
