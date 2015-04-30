//
//  CNTWebAppSession.m
//  Connect SDK
//
//  Created by Jeremy White on 2/21/14.
//  Copyright (c) 2014 LG Electronics.
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

#import "CNTWebAppSession.h"
#import "CNTConnectError.h"


@implementation CNTWebAppSession

- (instancetype) initWithJSONObject:(NSDictionary*)dict
{
    return nil; // not supported
}

- (NSDictionary*) toJSONObject
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    
    if (self.launchSession) {
        dict[@"launchSession"] = [self.launchSession toJSONObject];
    }
    
    if (self.service && self.service.serviceDescription) {
        dict[@"serviceName"] = [self.service serviceName];
    }
    
    return dict;
}

- (instancetype)initWithLaunchSession:(CNTLaunchSession *)launchSession service:(CNTDeviceService *)service
{
    self = [super init];

    if (self)
    {
        _launchSession = launchSession;
        _service = service;
    }

    return self;
}

- (void) sendNotSupportedFailure:(FailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

#pragma mark - ServiceCommandDelegate methods

- (int)sendCommand:(CNTServiceCommand *)comm withPayload:(id)payload toURL:(NSURL *)URL
{
    return -1;
}

- (int)sendAsync:(CNTServiceAsyncCommand *)async withPayload:(id)payload toURL:(NSURL *)URL
{
    return -1;
}

- (int)sendSubscription:(CNTServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    return -1;
}

#pragma mark - Web App methods

- (CNTServiceSubscription *) subscribeWebAppStatus:(WebAppStatusBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];

    return nil;
}

- (void) connectWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) joinWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)disconnectFromWebApp { }

- (void)sendText:(NSString *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)sendJSON:(NSDictionary *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)pinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)unPinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)isWebAppPinned:(NSString *)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (CNTServiceSubscription *)subscribeIsWebAppPinned:(NSString*)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
   [self sendNotSupportedFailure:failure];
    return nil;
}

#pragma mark - Media Player

- (id <CNTMediaPlayer>) mediaPlayer
{
    return self;
}

- (CapabilityPriorityLevel) mediaPlayerPriority
{
    return CapabilityPriorityLevelLow;
}

- (void) displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) displayImage:(CNTMediaInfo *)mediaInfo
              success:(MediaPlayerDisplaySuccessBlock)success
              failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) displayImageWithMediaInfo:(CNTMediaInfo *)mediaInfo success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) playMedia:(CNTMediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) playMediaWithMediaInfo:(CNTMediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) closeMedia:(CNTLaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

#pragma mark - MediaControl
#pragma mark MediaControl required methods

- (id <CNTMediaControl>)mediaControl
{
    return self;
}

- (CapabilityPriorityLevel)mediaControlPriority
{
    return CapabilityPriorityLevelLow;
}

- (void)playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    id<CNTMediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl playWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

- (void)pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    id<CNTMediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl pauseWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

- (void)stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    id<CNTMediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl stopWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

- (void)rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    id<CNTMediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl rewindWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

- (void)fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    id<CNTMediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl fastForwardWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

#pragma mark MediaControl optional methods

- (void) seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (CNTServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];

    return nil;
}

- (void) getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (CNTServiceSubscription *)subscribeMediaInfoWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
    return nil;
}

@end
