//
//  CNTRokuService.m
//  ConnectSDK
//
//  Created by Jeremy White on 2/14/14.
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

#import "CNTRokuService.h"
#import "CNTConnectError.h"
#import "CTXMLReader.h"
#import "CNTConnectUtil.h"
#import "CNTDeviceServiceReachability.h"
#import "CNTDiscoveryManager.h"

@interface CNTRokuService () <CNTServiceCommandDelegate, CNTDeviceServiceReachabilityDelegate>
{
    CNTDIALService *_dialService;
    CNTDeviceServiceReachability *_serviceReachability;
}
@end

static NSMutableArray *registeredApps = nil;

@implementation CNTRokuService

+ (void) initialize
{
    registeredApps = [NSMutableArray arrayWithArray:@[
            @"YouTube",
            @"Netflix",
            @"Amazon"
    ]];
}

+ (NSDictionary *)discoveryParameters
{
    return @{
            @"serviceId" : kCNTConnectSDKRokuServiceId,
            @"ssdp" : @{
                    @"filter" : @"roku:ecp"
            }
    };
}

- (void) updateCapabilities
{
    NSArray *capabilities = @[
        kCNTLauncherAppList,
        kCNTLauncherApp,
        kCNTLauncherAppParams,
        kCNTLauncherAppStore,
        kCNTLauncherAppStoreParams,
        kCNTLauncherAppClose,

        kCNTMediaPlayerDisplayImage,
        kCNTMediaPlayerPlayVideo,
        kCNTMediaPlayerPlayAudio,
        kCNTMediaPlayerClose,
        kCNTMediaPlayerMetaDataTitle,

        kCNTMediaControlPlay,
        kCNTMediaControlPause,
        kCNTMediaControlRewind,
        kCNTMediaControlFastForward,

        kCNTTextInputControlSendText,
        kCNTTextInputControlSendEnter,
        kCNTTextInputControlSendDelete
    ];

    capabilities = [capabilities arrayByAddingObjectsFromArray:kCNTKeyControlCapabilities];

    [self setCapabilities:capabilities];
}

+ (void) registerApp:(NSString *)appId
{
    if (![registeredApps containsObject:appId])
        [registeredApps addObject:appId];
}

- (void) probeForApps
{
    [registeredApps enumerateObjectsUsingBlock:^(NSString *appName, NSUInteger idx, BOOL *stop)
    {
        [self hasApp:appName success:^(CNTAppInfo *appInfo)
        {
            NSString *capability = [NSString stringWithFormat:@"CNTLauncher.%@", appName];
            NSString *capabilityParams = [NSString stringWithFormat:@"CNTLauncher.%@.Params", appName];

            [self addCapabilities:@[capability, capabilityParams]];
        } failure:nil];
    }];
}

- (BOOL) isConnectable
{
    return YES;
}

- (void) connect
{
    NSString *targetPath = [NSString stringWithFormat:@"http://%@:%@/", self.serviceDescription.address, @(self.serviceDescription.port)];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    _serviceReachability = [CNTDeviceServiceReachability reachabilityWithTargetURL:targetURL];
    _serviceReachability.delegate = self;
    [_serviceReachability start];

    self.connected = YES;

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void) disconnect
{
    self.connected = NO;

    [_serviceReachability stop];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
}

- (void) didLoseReachability:(CNTDeviceServiceReachability *)reachability
{
    if (self.connected)
        [self disconnect];
    else
        [_serviceReachability stop];
}

- (void)setServiceDescription:(CNTServiceDescription *)serviceDescription
{
    [super setServiceDescription:serviceDescription];

    self.serviceDescription.port = 8060;
    NSString *commandPath = [NSString stringWithFormat:@"http://%@:%@", self.serviceDescription.address, @(self.serviceDescription.port)];
    self.serviceDescription.commandURL = [NSURL URLWithString:commandPath];

    [self probeForApps];
}

- (CNTDIALService *) dialService
{
    if (!_dialService)
    {
        CNTConnectableDevice *device = [[CNTDiscoveryManager sharedManager].allDevices objectForKey:self.serviceDescription.address];
        __block CNTDIALService *foundService;

        [device.services enumerateObjectsUsingBlock:^(CNTDeviceService *service, NSUInteger idx, BOOL *stop)
        {
            if ([service isKindOfClass:[CNTDIALService class]])
            {
                foundService = (CNTDIALService *) service;
                *stop = YES;
            }
        }];

        if (foundService)
            _dialService = foundService;
    }

    return _dialService;
}

#pragma mark - ServiceCommandDelegate

- (int) sendCommand:(CNTServiceCommand *)command withPayload:(NSDictionary *)payload toURL:(NSURL *)URL
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setTimeoutInterval:6];
    [request addValue:@"text/plain;charset=\"utf-8\"" forHTTPHeaderField:@"Content-Type"];

    if (payload || [command.HTTPMethod isEqualToString:@"POST"])
    {
        [request setHTTPMethod:@"POST"];

        if (payload)
        {
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
            [request addValue:[NSString stringWithFormat:@"%i", (unsigned int) [jsonData length]] forHTTPHeaderField:@"Content-Length"];
            [request setHTTPBody:jsonData];
        }
    } else
    {
        [request setHTTPMethod:@"GET"];
        [request addValue:@"0" forHTTPHeaderField:@"Content-Length"];
    }

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (connectionError)
        {
            if (command.callbackError)
                dispatch_on_main(^{ command.callbackError(connectionError); });
        } else
        {
            if ([httpResponse statusCode] < 200 || [httpResponse statusCode] >= 300)
            {
                NSError *error = [CNTConnectError generateErrorWithCode:CNTConnectStatusCodeTvError andDetails:nil];
                
                if (command.callbackError)
                    command.callbackError(error);
                
                return;
            }
            
            NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

            if (command.callbackComplete)
                dispatch_on_main(^{ command.callbackComplete(dataString); });
        }
    }];

    // TODO: need to implement callIds in here
    return 0;
}

#pragma mark - Launcher

- (id <CNTLauncher>)launcher
{
    return self;
}

- (CNTCapabilityPriorityLevel)launcherPriority
{
    return CNTCapabilityPriorityLevelHigh;
}

- (void)launchApp:(NSString *)appId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (!appId)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeArgumentError andDetails:@"You must provide an appId."]);
        return;
    }

    CNTAppInfo *appInfo = [CNTAppInfo appInfoForId:appId];

    [self launchAppWithInfo:appInfo params:nil success:success failure:failure];
}

- (void)launchAppWithInfo:(CNTAppInfo *)appInfo success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self launchAppWithInfo:appInfo params:nil success:success failure:failure];
}

- (void)launchAppWithInfo:(CNTAppInfo *)appInfo params:(NSDictionary *)params success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (!appInfo || !appInfo.id)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeArgumentError andDetails:@"You must provide a valid CNTAppInfo object."]);
        return;
    }

    NSURL *targetURL = [self.serviceDescription.commandURL URLByAppendingPathComponent:@"launch"];
    targetURL = [targetURL URLByAppendingPathComponent:appInfo.id];
    
    if (params)
    {
        __block NSString *queryParams = @"";
        __block int count = 0;
        
        [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
            NSString *prefix = (count == 0) ? @"?" : @"&";
            
            NSString *urlSafeKey = [CNTConnectUtil urlEncode:key];
            NSString *urlSafeValue = [CNTConnectUtil urlEncode:value];
            
            NSString *appendString = [NSString stringWithFormat:@"%@%@=%@", prefix, urlSafeKey, urlSafeValue];
            queryParams = [queryParams stringByAppendingString:appendString];
            
            count++;
        }];
        
        NSString *targetPath = [NSString stringWithFormat:@"%@%@", targetURL.absoluteString, queryParams];
        targetURL = [NSURL URLWithString:targetPath];
    }

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:nil];
    command.callbackComplete = ^(id responseObject)
    {
        CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:appInfo.id];
        launchSession.name = appInfo.name;
        launchSession.sessionType = CNTLaunchSessionTypeApp;
        launchSession.service = self;

        if (success)
            success(launchSession);
    };
    command.callbackError = failure;
    [command send];
}

- (void)launchYouTube:(NSString *)contentId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self launchYouTube:contentId startTime:0.0 success:success failure:failure];
}

- (void) launchYouTube:(NSString *)contentId startTime:(float)startTime success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dialService)
        [self.dialService.launcher launchYouTube:contentId startTime:startTime success:success failure:failure];
    else
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:@"Cannot reach DIAL service for launching with provided start time"]);
    }
}

- (void) launchAppStore:(NSString *)appId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    CNTAppInfo *appInfo = [CNTAppInfo appInfoForId:@"11"];
    appInfo.name = @"Channel Store";

    NSDictionary *params;

    if (appId && appId.length > 0)
        params = @{ @"contentId" : appId };

    [self launchAppWithInfo:appInfo params:params success:success failure:failure];
}

- (void)launchBrowser:(NSURL *)target success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)launchHulu:(NSString *)contentId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)launchNetflix:(NSString *)contentId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self getAppListWithSuccess:^(NSArray *appList)
    {
        __block CNTAppInfo *foundAppInfo;

        [appList enumerateObjectsUsingBlock:^(CNTAppInfo *appInfo, NSUInteger idx, BOOL *stop)
        {
            if ([appInfo.name isEqualToString:@"Netflix"])
            {
                foundAppInfo = appInfo;
                *stop = YES;
            }
        }];

        if (foundAppInfo)
        {
            NSMutableDictionary *params = [NSMutableDictionary new];
            params[@"mediaType"] = @"movie";
            if (contentId && contentId.length > 0) params[@"contentId"] = contentId;

            [self launchAppWithInfo:foundAppInfo params:params success:success failure:failure];
        } else
        {
            if (failure)
                failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Netflix app could not be found on TV"]);
        }
    } failure:failure];
}

- (void)closeApp:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.keyControl homeWithSuccess:success failure:failure];
}

- (void)getAppListWithSuccess:(CNTAppListSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSURL *targetURL = [self.serviceDescription.commandURL URLByAppendingPathComponent:@"query"];
    targetURL = [targetURL URLByAppendingPathComponent:@"apps"];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = ^(NSString *responseObject)
    {
        NSError *xmlError;
        NSDictionary *appListDictionary = [CTXMLReader dictionaryForXMLString:responseObject error:&xmlError];

        if (!xmlError)
        {
            NSArray *apps = [[appListDictionary objectForKey:@"apps"] objectForKey:@"app"];
            NSMutableArray *appList = [NSMutableArray new];

            [apps enumerateObjectsUsingBlock:^(NSDictionary *appInfoDictionary, NSUInteger idx, BOOL *stop)
            {
                CNTAppInfo *appInfo = [self appInfoFromDictionary:appInfoDictionary];
                [appList addObject:appInfo];
            }];

            if (success)
                success([NSArray arrayWithArray:appList]);
        }
    };
    command.callbackError = failure;
    [command send];
}

- (void)getAppState:(CNTLaunchSession *)launchSession success:(CNTAppStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (CNTServiceSubscription *)subscribeAppState:(CNTLaunchSession *)launchSession success:(CNTAppStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (void)getRunningAppWithSuccess:(CNTAppInfoSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (CNTServiceSubscription *)subscribeRunningAppWithSuccess:(CNTAppInfoSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

#pragma mark - MediaPlayer

- (id <CNTMediaPlayer>)mediaPlayer
{
    return self;
}

- (CNTCapabilityPriorityLevel)mediaPlayerPriority
{
    return CNTCapabilityPriorityLevelHigh;
}

- (void)displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(CNTMediaPlayerDisplaySuccessBlock)success failure:(CNTFailureBlock)failure
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
    NSURL *imageURL = mediaInfo.url;
    if (!imageURL)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeArgumentError andDetails:@"You need to provide a video URL"]);
        
        return;
    }
    
    NSString *host = [NSString stringWithFormat:@"%@:%@", self.serviceDescription.address, @(self.serviceDescription.port)];
    
    NSString *applicationPath = [NSString stringWithFormat:@"15985?t=p&u=%@&h=%@&tr=crossfade",
                                 [CNTConnectUtil urlEncode:imageURL.absoluteString], // content path
                                 [CNTConnectUtil urlEncode:host] // host
                                 ];
    
    NSString *commandPath = [NSString pathWithComponents:@[
                                                           self.serviceDescription.commandURL.absoluteString,
                                                           @"input",
                                                           applicationPath
                                                           ]];
    
    NSURL *targetURL = [NSURL URLWithString:commandPath];
    
    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:nil];
    command.HTTPMethod = @"POST";
    command.callbackComplete = ^(id responseObject)
    {
        CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:@"15985"];
        launchSession.name = @"simplevideoplayer";
        launchSession.sessionType = CNTLaunchSessionTypeMedia;
        launchSession.service = self;
        
        CNTMediaLaunchObject *launchObject = [[CNTMediaLaunchObject alloc] initWithLaunchSession:launchSession andMediaControl:self.mediaControl];
        if(success){
            success(launchObject);
        }
    };
    command.callbackError = failure;
    [command send];
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
    NSURL *iconURL;
    if(mediaInfo.images){
        CNTImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    NSURL *mediaURL = mediaInfo.url;
    NSString *mimeType = mediaInfo.mimeType;
    NSString *title = mediaInfo.title;
    NSString *description = mediaInfo.description;
    if (!mediaURL)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeArgumentError andDetails:@"You need to provide a media URL"]);
        
        return;
    }
    
    NSString *mediaType = [[mimeType componentsSeparatedByString:@"/"] lastObject];
    BOOL isVideo = [[mimeType substringToIndex:1] isEqualToString:@"v"];
    
    NSString *host = [NSString stringWithFormat:@"%@:%@", self.serviceDescription.address, @(self.serviceDescription.port)];
    NSString *applicationPath;
    
    if (isVideo)
    {
        applicationPath = [NSString stringWithFormat:@"15985?t=v&u=%@&k=(null)&h=%@&videoName=%@&videoFormat=%@",
                           [CNTConnectUtil urlEncode:mediaURL.absoluteString], // content path
                           [CNTConnectUtil urlEncode:host], // host
                           title ? [CNTConnectUtil urlEncode:title] : @"(null)", // video name
                           ensureString(mediaType) // video format
                           ];
    } else
    {
        applicationPath = [NSString stringWithFormat:@"15985?t=a&u=%@&k=(null)&h=%@&songname=%@&artistname=%@&songformat=%@&albumarturl=%@",
                           [CNTConnectUtil urlEncode:mediaURL.absoluteString], // content path
                           [CNTConnectUtil urlEncode:host], // host
                           title ? [CNTConnectUtil urlEncode:title] : @"(null)", // song name
                           description ? [CNTConnectUtil urlEncode:description] : @"(null)", // artist name
                           ensureString(mediaType), // audio format
                           iconURL ? [CNTConnectUtil urlEncode:iconURL.absoluteString] : @"(null)"
                           ];
    }
    
    NSString *commandPath = [NSString pathWithComponents:@[
                                                           self.serviceDescription.commandURL.absoluteString,
                                                           @"input",
                                                           applicationPath
                                                           ]];
    
    NSURL *targetURL = [NSURL URLWithString:commandPath];
    
    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:nil];
    command.HTTPMethod = @"POST";
    command.callbackComplete = ^(id responseObject)
    {
        CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:@"15985"];
        launchSession.name = @"simplevideoplayer";
        launchSession.sessionType = CNTLaunchSessionTypeMedia;
        launchSession.service = self;
         CNTMediaLaunchObject *launchObject = [[CNTMediaLaunchObject alloc] initWithLaunchSession:launchSession andMediaControl:self.mediaControl];
         if(success){
            success(launchObject);
         }
    };
    command.callbackError = failure;
    [command send];
}

- (void)closeMedia:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.keyControl homeWithSuccess:success failure:failure];
}

#pragma mark - CNTMediaControl

- (id <CNTMediaControl>)mediaControl
{
    return self;
}

- (CNTCapabilityPriorityLevel)mediaControlPriority
{
    return CNTCapabilityPriorityLevelHigh;
}

- (void)playWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTRokuKeyCodePlay success:success failure:failure];
}

- (void)pauseWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    // Roku does not have pause, it only has play/pause
    [self sendKeyCode:CNTRokuKeyCodePlay success:success failure:failure];
}

- (void)stopWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)rewindWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTRokuKeyCodeRewind success:success failure:failure];
}

- (void)fastForwardWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTRokuKeyCodeFastForward success:success failure:failure];
}

- (void)seek:(NSTimeInterval)position success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)getPlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (CNTServiceSubscription *)subscribePlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (void)getPositionWithSuccess:(CNTMediaPositionSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (CNTServiceSubscription *)subscribeMediaInfoWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
    
    return nil;
}

#pragma mark - Key Control

- (id <CNTKeyControl>) keyControl
{
    return self;
}

- (CNTCapabilityPriorityLevel) keyControlPriority
{
    return CNTCapabilityPriorityLevelHigh;
}

- (void)upWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTRokuKeyCodeUp success:success failure:failure];
}

- (void)downWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTRokuKeyCodeDown success:success failure:failure];
}

- (void)leftWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTRokuKeyCodeLeft success:success failure:failure];
}

- (void)rightWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTRokuKeyCodeRight success:success failure:failure];
}

- (void)homeWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTRokuKeyCodeHome success:success failure:failure];
}

- (void)backWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTRokuKeyCodeBack success:success failure:failure];
}

- (void)okWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTRokuKeyCodeSelect success:success failure:failure];
}

- (void)sendKeyCode:(CNTRokuKeyCode)keyCode success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (keyCode > kCNTRokuKeyCodes.count)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeArgumentError andDetails:nil]);
        return;
    }

    NSString *keyCodeString = kCNTRokuKeyCodes[keyCode];

    [self sendKeyPress:keyCodeString success:success failure:failure];
}

#pragma mark - Text Input Control

- (id <CNTTextInputControl>) textInputControl
{
    return self;
}

- (CNTCapabilityPriorityLevel) textInputControlPriority
{
    return CNTCapabilityPriorityLevelNormal;
}

- (void) sendText:(NSString *)input success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    // TODO: optimize this with queueing similiar to webOS and Netcast services
    NSMutableArray *stringToSend = [NSMutableArray new];

    [input enumerateSubstringsInRange:NSMakeRange(0, input.length) options:(NSStringEnumerationByComposedCharacterSequences) usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop)
    {
        [stringToSend addObject:substring];
    }];

    [stringToSend enumerateObjectsUsingBlock:^(NSString *charToSend, NSUInteger idx, BOOL *stop)
    {

        NSString *codeToSend = [NSString stringWithFormat:@"%@%@", kCNTRokuKeyCodes[CNTRokuKeyCodeLiteral], [CNTConnectUtil urlEncode:charToSend]];

        [self sendKeyPress:codeToSend success:success failure:failure];
    }];
}

- (void)sendEnterWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTRokuKeyCodeEnter success:success failure:failure];
}

- (void)sendDeleteWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTRokuKeyCodeBackspace success:success failure:failure];
}

- (CNTServiceSubscription *) subscribeTextInputStatusWithSuccess:(CNTTextInputStatusInfoSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        [CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil];

    return nil;
}

#pragma mark - Helper methods

- (void) sendKeyPress:(NSString *)keyCode success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSURL *targetURL = [self.serviceDescription.commandURL URLByAppendingPathComponent:@"keypress"];
    targetURL = [NSURL URLWithString:[targetURL.absoluteString stringByAppendingPathComponent:keyCode]];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (CNTAppInfo *)appInfoFromDictionary:(NSDictionary *)appDictionary
{
    NSString *id = [appDictionary objectForKey:@"id"];
    NSString *name = [appDictionary objectForKey:@"text"];

    CNTAppInfo *appInfo = [CNTAppInfo appInfoForId:id];
    appInfo.name = name;
    appInfo.rawData = [appDictionary copy];

    return appInfo;
}

- (void) hasApp:(NSString *)appName success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.launcher getAppListWithSuccess:^(NSArray *appList)
    {
        if (appList)
        {
            __block CNTAppInfo *foundAppInfo;

            [appList enumerateObjectsUsingBlock:^(CNTAppInfo *appInfo, NSUInteger idx, BOOL *stop)
            {
                if ([appInfo.name isEqualToString:appName])
                {
                    foundAppInfo = appInfo;
                    *stop = YES;
                }
            }];

            if (foundAppInfo)
            {
                if (success)
                    success(foundAppInfo);
            } else
            {
                if (failure)
                    failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Could not find this app on the TV"]);
            }
        } else
        {
            if (failure)
                failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeTvError andDetails:@"Could not find any apps on the TV."]);
        }
    } failure:failure];
}

@end
