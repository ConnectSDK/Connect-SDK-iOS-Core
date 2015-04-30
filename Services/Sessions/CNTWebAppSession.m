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

- (void) sendNotSupportedFailure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
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

- (int)sendSubscription:(CNTServiceSubscription *)subscription type:(CNTServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    return -1;
}

#pragma mark - Web App methods

- (CNTServiceSubscription *) subscribeWebAppStatus:(CNTWebAppStatusBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];

    return nil;
}

- (void) connectWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) joinWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)disconnectFromWebApp { }

- (void)sendText:(NSString *)message success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)sendJSON:(NSDictionary *)message success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)pinWebApp:(NSString *)webAppId success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)unPinWebApp:(NSString *)webAppId success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)isWebAppPinned:(NSString *)webAppId success:(CNTWebAppPinStatusBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (CNTServiceSubscription *)subscribeIsWebAppPinned:(NSString*)webAppId success:(CNTWebAppPinStatusBlock)success failure:(CNTFailureBlock)failure
{
   [self sendNotSupportedFailure:failure];
    return nil;
}

#pragma mark - Media Player

- (id <CNTMediaPlayer>) mediaPlayer
{
    return self;
}

- (CNTCapabilityPriorityLevel) mediaPlayerPriority
{
    return CNTCapabilityPriorityLevelLow;
}

- (void) displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(CNTMediaPlayerDisplaySuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) displayImage:(CNTMediaInfo *)mediaInfo
              success:(CNTMediaPlayerDisplaySuccessBlock)success
              failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) displayImageWithMediaInfo:(CNTMediaInfo *)mediaInfo success:(CNTMediaPlayerSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(CNTMediaPlayerDisplaySuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) playMedia:(CNTMediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(CNTMediaPlayerDisplaySuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) playMediaWithMediaInfo:(CNTMediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(CNTMediaPlayerSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) closeMedia:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

#pragma mark - CNTMediaControl
#pragma mark CNTMediaControl required methods

- (id <CNTMediaControl>)mediaControl
{
    return self;
}

- (CNTCapabilityPriorityLevel)mediaControlPriority
{
    return CNTCapabilityPriorityLevelLow;
}

- (void)playWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    id<CNTMediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl playWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

- (void)pauseWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    id<CNTMediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl pauseWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

- (void)stopWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    id<CNTMediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl stopWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

- (void)rewindWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    id<CNTMediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl rewindWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

- (void)fastForwardWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    id<CNTMediaControl> mediaControl;

    if (self.service && [self.service respondsToSelector:@selector(mediaControl)])
        mediaControl = [(id)self.service mediaControl];

    if (mediaControl)
        [mediaControl fastForwardWithSuccess:success failure:failure];
    else
        [self sendNotSupportedFailure:failure];
}

#pragma mark CNTMediaControl optional methods

- (void) seek:(NSTimeInterval)position success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)closeWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void) getPlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (void)getDurationWithSuccess:(CNTMediaDurationSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (CNTServiceSubscription *)subscribePlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];

    return nil;
}

- (void) getPositionWithSuccess:(CNTMediaPositionSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

- (CNTServiceSubscription *)subscribeMediaInfoWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
    return nil;
}

@end
