//
//  CNTAirPlayService.m
//  Connect SDK
//
//  Created by Jeremy White on 4/18/14.
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

#import "CNTAirPlayService.h"
#import "CNTConnectError.h"


@interface CNTAirPlayService () <UIWebViewDelegate, CNTServiceCommandDelegate, UIAlertViewDelegate>

@end

static CNTAirPlayServiceMode airPlayServiceMode;

@implementation CNTAirPlayService

@synthesize httpService = _httpService;
@synthesize mirroredService = _mirroredService;

+ (void)setAirPlayServiceMode:(CNTAirPlayServiceMode)serviceMode
{
    airPlayServiceMode = serviceMode;
}

+ (CNTAirPlayServiceMode) serviceMode
{
    return airPlayServiceMode;
}

+ (NSDictionary *) discoveryParameters
{
    return @{
        @"serviceId" : kCNTConnectSDKAirPlayServiceId,
        @"zeroconf" : @{
                @"filter" : @"_airplay._tcp"
        }
    };
}

- (void) updateCapabilities
{
    NSArray *caps = [NSArray array];

    if ([CNTAirPlayService serviceMode] == CNTAirPlayServiceModeMedia)
    {
        caps = [caps arrayByAddingObjectsFromArray:@[
                kCNTMediaPlayerDisplayImage,
                kCNTMediaPlayerPlayVideo,
                kCNTMediaPlayerPlayAudio,
                kCNTMediaPlayerClose,
                kCNTMediaPlayerMetaDataMimeType
        ]];

        caps = [caps arrayByAddingObjectsFromArray:@[
                kCNTMediaControlPlay,
                kCNTMediaControlPause,
                kCNTMediaControlStop,
                kCNTMediaControlRewind,
                kCNTMediaControlFastForward,
                kCNTMediaControlPlayState,
                kCNTMediaControlDuration,
                kCNTMediaControlPosition,
                kCNTMediaControlSeek
        ]];
    } else if ([CNTAirPlayService serviceMode] == CNTAirPlayServiceModeWebApp)
    {
        caps = [caps arrayByAddingObjectsFromArray:@[
                kCNTWebAppLauncherLaunch,
                kCNTWebAppLauncherMessageSend,
                kCNTWebAppLauncherMessageReceive,
                kCNTWebAppLauncherMessageSendJSON,
                kCNTWebAppLauncherMessageReceiveJSON,
                kCNTWebAppLauncherClose,
                kCNTWebAppLauncherConnect,
                kCNTWebAppLauncherJoin,
                kCNTWebAppLauncherDisconnect
        ]];
    }

    [super setCapabilities:caps];
}

- (void) sendNotSupportedFailure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (BOOL) isConnectable
{
    return YES;
}

- (void) connect
{
    if ([CNTAirPlayService serviceMode] == CNTAirPlayServiceModeWebApp)
        [self.mirroredService connect];

    if ([CNTAirPlayService serviceMode] == CNTAirPlayServiceModeMedia)
        [self.httpService connect];

     // delegate will receive connected message from either mirroredService or httpService, depending on the value CNTAirPlayService serviceMode property
}

- (void) disconnect
{
    if ([CNTAirPlayService serviceMode] == CNTAirPlayServiceModeWebApp && self.mirroredService.connected)
        [self.mirroredService disconnect];

    if ([CNTAirPlayService serviceMode] == CNTAirPlayServiceModeMedia && self.httpService.connected)
        [self.httpService disconnect];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
}

- (BOOL) connected
{
    switch ([CNTAirPlayService serviceMode])
    {
        case CNTAirPlayServiceModeWebApp:
            return self.mirroredService.connected;

        case CNTAirPlayServiceModeMedia:
            return self.httpService.connected;

        default:
            return NO;
    }
}

- (CNTAirPlayServiceHTTP *) httpService
{
    if (!_httpService)
        _httpService = [[CNTAirPlayServiceHTTP alloc] initWithAirPlayService:self];

    return _httpService;
}

- (CNTAirPlayServiceMirrored *) mirroredService
{
    if (!_mirroredService)
        _mirroredService = [[CNTAirPlayServiceMirrored alloc] initWithAirPlayService:self];

    return _mirroredService;
}

#pragma mark - MediaPlayer

- (id <CNTMediaPlayer>) mediaPlayer
{
    return self.httpService.mediaPlayer;
}

- (CNTCapabilityPriorityLevel) mediaPlayerPriority
{
    return self.mediaPlayer.mediaPlayerPriority;
}

- (void) displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(CNTMediaPlayerDisplaySuccessBlock)success failure:(CNTFailureBlock)failure
{
    CNTMediaInfo *mediaInfo = [[CNTMediaInfo alloc] initWithURL:imageURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;
    CNTImageInfo *imageInfo = [[CNTImageInfo alloc] initWithURL:iconURL type:CNTImageTypeThumb];
    [mediaInfo addImage:imageInfo];
    
    [self displayImageWithMediaInfo:mediaInfo success:^(CNTMediaLaunchObject *mediaLanchObject) {
        success(mediaLanchObject.session,mediaLanchObject.mediaControl);
    } failure:failure];
}

- (void) displayImage:(CNTMediaInfo *)mediaInfo
              success:(CNTMediaPlayerDisplaySuccessBlock)success
              failure:(CNTFailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        CNTImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    [self displayImage:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType success:success failure:failure];
}

- (void) displayImageWithMediaInfo:(CNTMediaInfo *)mediaInfo success:(CNTMediaPlayerSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaPlayer displayImageWithMediaInfo:mediaInfo success:success failure:failure];
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(CNTMediaPlayerDisplaySuccessBlock)success failure:(CNTFailureBlock)failure
{
    CNTMediaInfo *mediaInfo = [[CNTMediaInfo alloc] initWithURL:mediaURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;
    CNTImageInfo *imageInfo = [[CNTImageInfo alloc] initWithURL:iconURL type:CNTImageTypeThumb];
    [mediaInfo addImage:imageInfo];
    [self playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop success:^(CNTMediaLaunchObject *mediaLanchObject) {
        success(mediaLanchObject.session,mediaLanchObject.mediaControl);
    } failure:failure];
}

- (void) playMedia:(CNTMediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(CNTMediaPlayerDisplaySuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        CNTImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    [self playMedia:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType shouldLoop:shouldLoop success:success failure:failure];
}

- (void) playMediaWithMediaInfo:(CNTMediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(CNTMediaPlayerSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaPlayer playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop success:success failure:failure];
}

- (void) closeMedia:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaPlayer closeMedia:launchSession success:success failure:failure];
}

#pragma mark - Media Control

- (id <CNTMediaControl>) mediaControl
{
    return self.httpService.mediaControl;
}

- (CNTCapabilityPriorityLevel) mediaControlPriority
{
    return self.mediaControl.mediaControlPriority;
}

- (void) playWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaControl playWithSuccess:success failure:failure];
}

- (void) pauseWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaControl pauseWithSuccess:success failure:failure];
}

- (void) stopWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaControl stopWithSuccess:success failure:failure];
}

- (void) rewindWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaControl rewindWithSuccess:success failure:failure];
}

- (void) fastForwardWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaControl fastForwardWithSuccess:success failure:failure];
}

- (void) getDurationWithSuccess:(CNTMediaDurationSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaControl getDurationWithSuccess:success failure:failure];
}

- (void) getPlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaControl getPlayStateWithSuccess:success failure:failure];
}

- (void) getPositionWithSuccess:(CNTMediaPositionSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaControl getPositionWithSuccess:success failure:failure];
}

- (void) seek:(NSTimeInterval)position success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaControl seek:position success:success failure:failure];
}

- (CNTServiceSubscription *) subscribePlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    return [self.mediaControl subscribePlayStateWithSuccess:success failure:failure];
}

- (CNTServiceSubscription *)subscribeMediaInfoWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
   return [self.mediaControl subscribeMediaInfoWithSuccess:success failure:failure];
}


#pragma mark - Helpers

- (void) closeLaunchSession:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (launchSession.sessionType == CNTLaunchSessionTypeWebApp)
    {
        [self.webAppLauncher closeWebApp:launchSession success:success failure:failure];
    } else if (launchSession.sessionType == CNTLaunchSessionTypeMedia)
    {
        [self.mediaPlayer closeMedia:launchSession success:success failure:failure];
    } else
    {
        if (failure)
            dispatch_on_main(^{ failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Could not find CNTDeviceService responsible for closing this CNTLaunchSession"]); });
    }
}

#pragma mark - CNTWebAppLauncher

- (id <CNTWebAppLauncher>) webAppLauncher
{
    return self.mirroredService.webAppLauncher;
}

- (CNTCapabilityPriorityLevel) webAppLauncherPriority
{
    return self.webAppLauncher.webAppLauncherPriority;
}

- (void) launchWebApp:(NSString *)webAppId success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId success:success failure:failure];
}

- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId params:params success:success failure:failure];
}

- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId params:params relaunchIfRunning:relaunchIfRunning success:success failure:failure];
}

- (void) launchWebApp:(NSString *)webAppId relaunchIfRunning:(BOOL)relaunchIfRunning success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId relaunchIfRunning:YES success:success failure:failure];
}

- (void) joinWebApp:(CNTLaunchSession *)webAppLaunchSession success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.webAppLauncher joinWebApp:webAppLaunchSession success:success failure:failure];
}

- (void) joinWebAppWithId:(NSString *)webAppId success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.webAppLauncher joinWebAppWithId:webAppId success:success failure:failure];
}

- (void) closeWebApp:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.webAppLauncher closeWebApp:launchSession success:success failure:failure];
}

- (void) pinWebApp:(NSString *)webAppId success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendNotSupportedFailure:failure];
}

-(void)unPinWebApp:(NSString *)webAppId success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
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

@end
