//
//  CNTAirPlayServiceHTTP.m
//  Connect SDK
//
//  Created by Jeremy White on 5/28/14.
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

#import "CNTAirPlayServiceHTTP_Private.h"
#import "CNTAirPlayServiceHTTPKeepAlive.h"
#import "CNTDeviceService.h"
#import "CNTAirPlayService.h"
#import "CNTConnectError.h"
#import "CNTDeviceServiceReachability.h"
#import "CTGuid.h"
#import "GCDWebServer.h"

#import "CTASIHTTPRequest.h"

@interface CNTAirPlayServiceHTTP () <CNTServiceCommandDelegate, CNTDeviceServiceReachabilityDelegate>

@property (nonatomic, readonly) UIBackgroundTaskIdentifier backgroundTaskId;
@property (nonatomic, readonly) CNTDeviceServiceReachability *serviceReachability;
@property (nonatomic, readonly) NSString *sessionId;
@property (nonatomic, readonly) NSString *assetId;
@property (nonatomic, readonly) GCDWebServer *subscriptionServer;
@property (nonatomic, readonly) dispatch_queue_t networkingQueue;
@property (nonatomic, readonly) dispatch_queue_t imageProcessingQueue;
@property (nonatomic, strong) CNTAirPlayServiceHTTPKeepAlive *keepAlive;

@end

@implementation CNTAirPlayServiceHTTP

- (instancetype) initWithAirPlayService:(CNTAirPlayService *)service
{
    self = [super init];

    if (self)
    {
        _service = service;
        _backgroundTaskId = UIBackgroundTaskInvalid;
        _networkingQueue = dispatch_queue_create("com.connectsdk.CNTAirPlayServiceHTTP.Networking", DISPATCH_QUEUE_SERIAL);
        _imageProcessingQueue = dispatch_queue_create("com.connectsdk.CNTAirPlayServiceHTTP.ImageProcessing", DISPATCH_QUEUE_SERIAL);
    }

    return self;
}

#pragma mark - Connection & Reachability

- (void) connect
{
    _sessionId = [[CTGuid randomGuid] stringValue];

    _connected = YES;

    _serviceReachability = [CNTDeviceServiceReachability reachabilityWithTargetURL:self.service.serviceDescription.commandURL];
    _serviceReachability.delegate = self;
    [_serviceReachability start];

    if (self.service.connected && self.service.delegate && [self.service.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.service.delegate deviceServiceConnectionSuccess:self.service]; });
}

- (void) disconnect
{
    _sessionId = nil;

    if (self.backgroundTaskId != UIBackgroundTaskInvalid)
    {
        dispatch_async(self.networkingQueue, ^{
            [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskId];
            _backgroundTaskId = UIBackgroundTaskInvalid;
        });
    }

    if (_serviceReachability)
        [_serviceReachability stop];

    _connected = NO;
}

- (void) didLoseReachability:(CNTDeviceServiceReachability *)reachability
{
    if (self.connected)
    {
        [self.service disconnect];
        [self disconnect];
    } else
        [_serviceReachability stop];
}

#pragma mark - Getters & Setters

/// Returns the set delegate property value or self.
- (id<CNTServiceCommandDelegate>)serviceCommandDelegate {
    return _serviceCommandDelegate ?: self;
}

#pragma mark - Command management

- (int) sendCommand:(CNTServiceCommand *)command withPayload:(id)payload toURL:(NSURL *)URL
{
    CTASIHTTPRequest *request = [CTASIHTTPRequest requestWithURL:command.target];

    if (payload || [command.HTTPMethod isEqualToString:@"POST"] || [command.HTTPMethod isEqualToString:@"PUT"])
    {
        if (payload)
        {
            NSData *payloadData;
            NSString *contentType;

            if ([payload isKindOfClass:[NSString class]])
            {
                NSString *payloadString = (NSString *)payload;
                payloadData = [payloadString dataUsingEncoding:NSUTF8StringEncoding];
                contentType = @"text/parameters";
            } else if ([payload isKindOfClass:[NSDictionary class]])
            {
                NSError *parseError;
                payloadData = [NSPropertyListSerialization dataWithPropertyList:payload format:NSPropertyListBinaryFormat_v1_0 options:0 error:&parseError];

                if (parseError || !payloadData)
                {
                    NSError *error = parseError;

                    if (!error)
                        error = [CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Error occurred while parsing property list"];

                    if (command.callbackError)
                        dispatch_on_main(^{ command.callbackError(error); });

                    return -1;
                }

                contentType = @"application/x-apple-binary-plist";
            } else if ([payload isKindOfClass:[NSData class]])
            {
                payloadData = payload;
                contentType = @"image/jpeg";
            }

            if (payloadData == nil)
            {
                if (command.callbackError)
                    command.callbackError([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Unknown error preparing message to send"]);

                return -1;
            }

            [request addRequestHeader: @"Content-Length" value:[NSString stringWithFormat:@"%i", (unsigned int) [payloadData length]]];
            [request addRequestHeader: @"Content-Type" value:contentType];
            [request addRequestHeader: @"Connection" value:@"Keep-Alive"];
            [request setPostBody:[NSMutableData dataWithData:payloadData]];
        } else
        {
            [request addRequestHeader: @"Content-Length" value:@"0"];
        }

        DLog(@"[OUT] : %@ \n %@", request.requestHeaders, payload);
    } else
    {
        [request addRequestHeader: @"Content-Length" value:@"0"];

        DLog(@"[OUT] : %@", request.requestHeaders);
    }

    [request setRequestMethod:command.HTTPMethod];

    if (self.sessionId)
        [request addRequestHeader:@"X-Apple-Session-ID" value:self.sessionId];

    if (self.assetId)
        [request addRequestHeader:@"X-Apple-AssetKey" value:self.assetId];

    [request setShouldAttemptPersistentConnection:YES];
    [request setShouldContinueWhenAppEntersBackground:YES];
    
    __weak CTASIHTTPRequest *weakRequest = request;
    
    [request setCompletionBlock:^{
        if (!weakRequest)
        {
            if (command.callbackError)
                dispatch_on_main(^{ command.callbackError([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeSocketError andDetails:@"Could not access request data"]); });
            
            return;
        }

        CTASIHTTPRequest *strongRequest = weakRequest;
        
        if (strongRequest.responseStatusCode == 200)
        {
            NSError *xmlError;
            NSMutableDictionary *plist = [NSPropertyListSerialization propertyListWithData:strongRequest.responseData options:NSPropertyListImmutable format:NULL error:&xmlError];

            if (xmlError)
            {
                if (command.callbackComplete)
                    dispatch_on_main(^{ command.callbackComplete(strongRequest.responseData); });
            } else
            {
                if (plist)
                {
                    if (command.callbackComplete)
                        dispatch_on_main(^{ command.callbackComplete(plist); });
                }
            }
        } else
        {
            if (command.callbackError)
                dispatch_on_main(^{ command.callbackError([CNTConnectError generateErrorWithCode:strongRequest.responseStatusCode andDetails:nil]); });
        }
    }];

    dispatch_async(self.networkingQueue, ^void {
        // this will prevent the connection dropping on background/sleep modes
        if (self.backgroundTaskId == UIBackgroundTaskInvalid)
            _backgroundTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:NULL];

        [request startSynchronous];
    });

    return -1;
}

- (int) sendSubscription:(CNTServiceSubscription *)subscription type:(CNTServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    return -1;
}

#pragma mark - Media Player

- (id <CNTMediaPlayer>) mediaPlayer
{
    return self;
}

- (CNTCapabilityPriorityLevel) mediaPlayerPriority
{
    return CNTCapabilityPriorityLevelHigh;
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
    _assetId = [[CTGuid randomGuid] stringValue];
    
    NSString *commandPathComponent = @"photo";
    NSURL *commandURL = [self.service.serviceDescription.commandURL URLByAppendingPathComponent:commandPathComponent];
    
    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"POST";
    command.callbackComplete = ^(id responseObject) {
        CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:commandPathComponent];
        launchSession.sessionType = CNTLaunchSessionTypeMedia;
        launchSession.service = self.service;
        launchSession.sessionId = self.sessionId;
        
        CNTMediaLaunchObject *launchObject = [[CNTMediaLaunchObject alloc] initWithLaunchSession:launchSession andMediaControl:self.mediaControl];
        if(success){
            dispatch_on_main(^{ success(launchObject); });
        }
    };
    
    command.callbackError = failure;
    
    dispatch_async(self.imageProcessingQueue, ^{
        NSError *downloadError;
        NSURL *imageURL = mediaInfo.url;
        NSData *downloadedImageData = [NSData dataWithContentsOfURL:imageURL options:0 error:&downloadError];
        
        if (!downloadedImageData || downloadError)
        {
            if (failure)
            {
                if (downloadError)
                    dispatch_on_main(^{ failure(downloadError); });
                else
                    dispatch_on_main(^{ failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Could not download requested image"]); });
            }
            
            return;
        }
        
        NSData *processedImageData;
        
        if ([imageURL.absoluteString hasSuffix:@"jpg"] || [imageURL.absoluteString hasSuffix:@"jpeg"])
            processedImageData = downloadedImageData;
        else
        {
            UIImage *image = [UIImage imageWithData:downloadedImageData];
            
            if (image)
            {
                processedImageData = UIImageJPEGRepresentation(image, 1.0);
                
                if (!processedImageData)
                {
                    if (failure)
                        dispatch_on_main(^{ failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Could not convert downloaded image to JPEG format"]); });
                    
                    return;
                }
            } else
            {
                if (failure)
                    dispatch_on_main(^{ failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Could not convert downloaded data to a suitable image format"]); });
                
                return;
            }
        }
        
        command.payload = processedImageData;
        [command send];
    });
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
    _assetId = [[CTGuid randomGuid] stringValue];
    
    NSMutableDictionary *plist = [NSMutableDictionary new];
    plist[@"Content-Location"] = mediaInfo.url.absoluteString;
    plist[@"Start-Position"] = @(0.0);
    
    NSError *parseError;
    NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 options:0 error:&parseError];
    
    if (parseError || !plistData)
    {
        NSError *error = parseError;
        
        if (!error)
            error = [CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Error occurred while parsing property list"];
        
        if (failure)
            failure(error);
        
        return;
    }
    
    NSString *commandPathComponent = @"play";
    NSURL *commandURL = [self.service.serviceDescription.commandURL URLByAppendingPathComponent:commandPathComponent];
    
    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:commandURL payload:plist];
    command.HTTPMethod = @"POST";
    command.callbackComplete = ^(id responseObject) {
        CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:commandPathComponent];
        launchSession.sessionType = CNTLaunchSessionTypeMedia;
        launchSession.service = self.service;
        launchSession.sessionId = self.sessionId;
        
        [self startKeepAliveTimer];
        
        CNTMediaLaunchObject *launchObject = [[CNTMediaLaunchObject alloc] initWithLaunchSession:launchSession andMediaControl:self.mediaControl];
        if(success){
             dispatch_on_main(^{ success(launchObject); });
        }
    };
    command.callbackError = failure;
    
    [command send];
}

- (void) closeMedia:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaControl stopWithSuccess:success failure:failure];
}

#pragma mark - Media Control

- (id <CNTMediaControl>) mediaControl
{
    return self;
}

- (CNTCapabilityPriorityLevel) mediaControlPriority
{
    return CNTCapabilityPriorityLevelHigh;
}

- (void) playWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *commandPath = [NSString stringWithFormat:@"%@rate?value=1.000000", self.service.serviceDescription.commandURL.absoluteString];
    NSURL *commandURL = [NSURL URLWithString:commandPath];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"POST";
    command.callbackComplete = success;
    command.callbackError = failure;

    [command send];
}

- (void) pauseWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *commandPath = [NSString stringWithFormat:@"%@rate?value=0.000000", self.service.serviceDescription.commandURL.absoluteString];
    NSURL *commandURL = [NSURL URLWithString:commandPath];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"POST";
    command.callbackComplete = success;
    command.callbackError = failure;

    [command send];
}

- (void) stopWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *commandPathComponent = @"stop";
    NSURL *commandURL = [self.service.serviceDescription.commandURL URLByAppendingPathComponent:commandPathComponent];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"POST";
    command.callbackComplete = ^(id responseObject) {
        _assetId = nil;
        [self stopKeepAliveTimer];

        if (success)
            success(responseObject);
    };
    command.callbackError = failure;

    [command send];
}

- (void) rewindWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *commandPath = [NSString stringWithFormat:@"%@rate?value=-2.000000", self.service.serviceDescription.commandURL.absoluteString];
    NSURL *commandURL = [NSURL URLWithString:commandPath];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"POST";
    command.callbackComplete = success;
    command.callbackError = failure;

    [command send];
}

- (void) fastForwardWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *commandPath = [NSString stringWithFormat:@"%@rate?value=2.000000", self.service.serviceDescription.commandURL.absoluteString];
    NSURL *commandURL = [NSURL URLWithString:commandPath];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"POST";
    command.callbackComplete = success;
    command.callbackError = failure;

    [command send];
}

- (void) getDurationWithSuccess:(CNTMediaDurationSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *commandPathComponent = [NSString stringWithFormat:@"playback-info"];
    NSURL *commandURL = [self.service.serviceDescription.commandURL URLByAppendingPathComponent:commandPathComponent];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = ^(id responseObject) {
        NSTimeInterval duration = [responseObject[@"duration"] floatValue];

        if (success)
            success(duration);
    };
    command.callbackError = failure;

    [command send];
}

- (void) getPlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *commandPathComponent = [NSString stringWithFormat:@"playback-info"];
    NSURL *commandURL = [self.service.serviceDescription.commandURL URLByAppendingPathComponent:commandPathComponent];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self.serviceCommandDelegate target:commandURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = ^(NSDictionary *responseObject) {
        CNTMediaControlPlayState playState = CNTMediaControlPlayStateUnknown;

        NSNumber *rateValue = responseObject[@"rate"];
        if (rateValue) {
            NSInteger rate = [rateValue integerValue];
            playState = ((rate == 0) ?
                         CNTMediaControlPlayStatePaused :
                         CNTMediaControlPlayStatePlaying);
        } else {
            NSNumber *readyToPlayValue = responseObject[@"readyToPlay"];
            if (readyToPlayValue && ([readyToPlayValue integerValue] == 0)) {
                playState = CNTMediaControlPlayStateFinished;
            }
        }

        if (success)
            success(playState);
    };
    command.callbackError = failure;

    [command send];
}

- (void) getPositionWithSuccess:(CNTMediaPositionSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *commandPathComponent = [NSString stringWithFormat:@"playback-info"];
    NSURL *commandURL = [self.service.serviceDescription.commandURL URLByAppendingPathComponent:commandPathComponent];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = ^(id responseObject) {
        NSTimeInterval position = [responseObject[@"position"] floatValue];

        if (success)
            success(position);
    };
    command.callbackError = failure;

    [command send];
}

- (void) seek:(NSTimeInterval)position success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *commandPath = [NSString stringWithFormat:@"%@scrub?position=%.06f", self.service.serviceDescription.commandURL.absoluteString, position];
    NSURL *commandURL = [NSURL URLWithString:commandPath];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:commandURL payload:nil];
    command.HTTPMethod = @"POST";
    command.callbackComplete = success;
    command.callbackError = failure;

    [command send];
}

- (CNTServiceSubscription *) subscribePlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (CNTServiceSubscription *)subscribeMediaInfoWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
    
    return nil;
}

- (void) playNextWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void) playPreviousWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)jumpToTrackWithIndex:(NSInteger)index success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

#pragma mark - Helpers

- (void)startKeepAliveTimer {
    self.keepAlive = [[CNTAirPlayServiceHTTPKeepAlive alloc] initWithCommandDelegate:self];
    self.keepAlive.commandURL = self.service.serviceDescription.commandURL;
    [self.keepAlive startTimer];
}

- (void)stopKeepAliveTimer {
    [self.keepAlive stopTimer];
    self.keepAlive = nil;
}

@end
