//
//  DLNAService.m
//  Connect SDK
//
//  Created by Jeremy White on 12/13/13.
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

#import "DLNAService.h"
#import "ConnectError.h"
#import "CTXMLReader.h"
#import "ConnectUtil.h"
#import "DeviceServiceReachability.h"
#import "DLNAHTTPServer.h"

#define kDataFieldName @"XMLData"
#define kActionFieldName @"SOAPAction"
#define kSubscriptionTimeoutSeconds 300

static const NSInteger kValueNotFound = -1;

@interface DLNAService() <ServiceCommandDelegate, DeviceServiceReachabilityDelegate>
{
//    NSOperationQueue *_commandQueue;
    NSURL *_avTransportControlURL;
    NSURL *_avTransportEventURL;
    NSURL *_renderingControlControlURL;
    NSURL *_renderingControlEventURL;

    DLNAHTTPServer *_httpServer;
    NSMutableDictionary *_httpServerSessionIds;

    DeviceServiceReachability *_serviceReachability;
}

@end

@implementation DLNAService

@synthesize serviceDescription = _serviceDescription;

- (void) updateCapabilities
{
    NSArray *capabilities = @[
        kMediaPlayerDisplayImage,
        kMediaPlayerPlayVideo,
        kMediaPlayerPlayAudio,
        kMediaPlayerClose,
        kMediaPlayerMetaDataTitle,
        kMediaPlayerMetaDataMimeType,
        kMediaControlPlay,
        kMediaControlPause,
        kMediaControlStop,
        kMediaControlSeek,
        kMediaControlPosition,
        kMediaControlDuration,
        kMediaControlPlayState,
        kMediaControlPlayStateSubscribe,
        kMediaControlMetadata,
        kMediaControlMetadataSubscribe
    ];

    capabilities = [capabilities arrayByAddingObjectsFromArray:kVolumeControlCapabilities];

    [self setCapabilities:capabilities];
}

+ (NSDictionary *) discoveryParameters
{
    return @{
            @"serviceId": kConnectSDKDLNAServiceId,
            @"ssdp":@{
                    @"filter":@"urn:schemas-upnp-org:device:MediaRenderer:1",
                    @"requiredServices":@[
                            @"urn:schemas-upnp-org:service:AVTransport:1",
                            @"urn:schemas-upnp-org:service:RenderingControl:1"
                    ]
            }
    };
}

- (id) initWithJSONObject:(NSDictionary *)dict
{
    // not supported
    return nil;
}

//- (NSDictionary *) toJSONObject
//{
//    // not supported
//    return nil;
//}

#pragma mark - Helper methods

//- (NSOperationQueue *)commandQueue
//{
//    if (_commandQueue == nil)
//    {
//        _commandQueue = [[NSOperationQueue alloc] init];
//    }
//
//    return _commandQueue;
//}

- (void)setServiceDescription:(ServiceDescription *)serviceDescription
{
    _serviceDescription = serviceDescription;
    
    if (_serviceDescription.locationXML)
    {
        [self updateControlURLs];

        if (!_httpServer)
            _httpServer = [[DLNAHTTPServer alloc] initWithService:self];
    } else
    {
        _avTransportControlURL = nil;
        _renderingControlControlURL = nil;
    }
}

- (void) updateControlURLs
{
    NSArray *serviceList = self.serviceDescription.serviceList;

    [serviceList enumerateObjectsUsingBlock:^(id service, NSUInteger idx, BOOL *stop) {
        NSString *serviceName = service[@"serviceId"][@"text"];
        NSString *controlPath = service[@"controlURL"][@"text"];
        NSString *eventPath = service[@"eventSubURL"][@"text"];
        NSString *controlURL = [NSString stringWithFormat:@"http://%@:%@%@",
                                                          self.serviceDescription.commandURL.host,
                                                          self.serviceDescription.commandURL.port,
                                                          controlPath];
        NSString *eventURL = [NSString stringWithFormat:@"http://%@:%@%@",
                                                          self.serviceDescription.commandURL.host,
                                                          self.serviceDescription.commandURL.port,
                                                          eventPath];

        if ([serviceName rangeOfString:@":AVTransport"].location != NSNotFound)
        {
            _avTransportControlURL = [NSURL URLWithString:controlURL];
            _avTransportEventURL = [NSURL URLWithString:eventURL];
        } else if ([serviceName rangeOfString:@":RenderingControl"].location != NSNotFound)
        {
            _renderingControlControlURL = [NSURL URLWithString:controlURL];
            _renderingControlEventURL = [NSURL URLWithString:eventURL];
        }
    }];
}

- (BOOL) isConnectable
{
    return YES;
}

- (void) connect
{
//    NSString *targetPath = [NSString stringWithFormat:@"http://%@:%@/", self.serviceDescription.address, @(self.serviceDescription.port)];
//    NSURL *targetURL = [NSURL URLWithString:targetPath];

    _serviceReachability = [DeviceServiceReachability reachabilityWithTargetURL:_avTransportControlURL];
    _serviceReachability.delegate = self;
    [_serviceReachability start];

    self.connected = YES;

    [_httpServer start];
    [self subscribeServices];

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

- (void) didLoseReachability:(DeviceServiceReachability *)reachability
{
    if (self.connected)
        [self disconnect];
    else
        [_serviceReachability stop];
}

#pragma mark -

/// Parses the DLNA notification and returns the value for the given key in the
/// specified channel.
- (NSInteger)valueForVolumeKey:(NSString *)key
                     atChannel:(NSString *)channelName
                    inResponse:(NSDictionary *)responseObject
{
    // this object is expected to be either a map of volume properties or
    // an array of maps for different channels
    id channelsObject = responseObject[@"Event"][@"InstanceID"][key];
    __block int volume = kValueNotFound;

    NSArray *channels = nil;
    if ([channelsObject isKindOfClass:[NSArray class]]) {
        channels = channelsObject;
    } else if ([channelsObject isKindOfClass:[NSDictionary class]]) {
        channels = [NSArray arrayWithObject:channelsObject];
    } else {
        DLog(@"Unexpected contents for volume notification (%@ object)",
             NSStringFromClass([channelsObject class]));
    }

    [channels enumerateObjectsUsingBlock:^(NSDictionary *channel, NSUInteger idx, BOOL *stop) {
        if ([channelName isEqualToString:channel[@"channel"]])
        {
            volume = [channel[@"val"] intValue];
            *stop = YES;
        }
    }];

    return volume;
}

#pragma mark - ServiceCommandDelegate

- (int) sendCommand:(ServiceCommand *)command withPayload:(NSDictionary *)payload toURL:(NSURL *)URL
{
    NSString *actionField = [payload objectForKey:kActionFieldName];
    NSString *xml = [payload objectForKey:kDataFieldName];

    NSData *xmlData = [xml dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setTimeoutInterval:30];
    [request addValue:@"text/xml;charset=\"utf-8\"" forHTTPHeaderField:@"Content-Type"];
    [request addValue:[NSString stringWithFormat:@"%i", (unsigned int) [xmlData length]] forHTTPHeaderField:@"Content-Length"];
    [request addValue:actionField forHTTPHeaderField:kActionFieldName];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:xmlData];

    DLog(@"[OUT] : %@ \n %@", [request allHTTPHeaderFields], xml);

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        NSError *xmlError;
        NSDictionary *dataXML = [CTXMLReader dictionaryForXMLData:data error:&xmlError];

        DLog(@"[IN] : %@ \n %@", [((NSHTTPURLResponse *)response) allHeaderFields], dataXML);

        if (connectionError)
        {
            if (command.callbackError)
                dispatch_on_main(^{ command.callbackError(connectionError); });
        } else if (xmlError)
        {
            if (command.callbackError)
                dispatch_on_main(^{ command.callbackError([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not parse command response"]); });
        } else
        {
            NSDictionary *upnpFault = [[[dataXML objectForKey:@"s:Envelope"] objectForKey:@"s:Body"] objectForKey:@"s:Fault"];

            if (upnpFault)
            {
                NSString *errorDescription = [[[[upnpFault objectForKey:@"detail"] objectForKey:@"UPnPError"] objectForKey:@"errorDescription"] objectForKey:@"text"];

                if (!errorDescription)
                    errorDescription = @"Unknown UPnP error";

                if (command.callbackError)
                    dispatch_on_main(^{ command.callbackError([ConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:errorDescription]); });
            } else
            {
                if (command.callbackComplete)
                    dispatch_on_main(^{ command.callbackComplete(dataXML); });
            }
        }
    }];

    // TODO: need to implement callIds in here
    return 0;
}

- (int) sendSubscription:(ServiceSubscription *)subscription type:(ServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    if (type == ServiceSubscriptionTypeSubscribe)
    {
        [_httpServer addSubscription:subscription];

        if (!_httpServer.isRunning)
        {
            [_httpServer start];
            [self subscribeServices];
        }
    } else
    {
        [_httpServer removeSubscription:subscription];

        if (!_httpServer.hasSubscriptions)
        {
            [self unsubscribeServices];
            [_httpServer stop];
        }
    }

    return -1;
}

#pragma mark - Subscriptions

- (void) subscribeServices
{
    _httpServerSessionIds = [NSMutableDictionary new];

    [_serviceDescription.serviceList enumerateObjectsUsingBlock:^(id service, NSUInteger idx, BOOL *stop) {
        NSString *serviceId = service[@"serviceId"][@"text"];
        NSString *eventPath = service[@"eventSubURL"][@"text"];
        NSString *commandPath = [NSString stringWithFormat:@"http://%@:%@%@",
                                                           self.serviceDescription.commandURL.host,
                                                           self.serviceDescription.commandURL.port,
                                                           eventPath];
        NSURL *eventSubURL = [NSURL URLWithString:commandPath];

        if ([eventPath hasPrefix:@"/"])
            eventPath = [eventPath substringFromIndex:1];

        NSString *serverPath = [[_httpServer getHostPath] stringByAppendingString:eventPath];
        serverPath = [NSString stringWithFormat:@"<%@>", serverPath];

        NSString *timeoutValue = [NSString stringWithFormat:@"Second-%d", kSubscriptionTimeoutSeconds];

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:eventSubURL];
        [request setHTTPMethod:@"SUBSCRIBE"];
        [request setValue:serverPath forHTTPHeaderField:@"CALLBACK"];
        [request setValue:@"upnp:event" forHTTPHeaderField:@"NT"];
        [request setValue:timeoutValue forHTTPHeaderField:@"TIMEOUT"];
        [request setValue:@"close" forHTTPHeaderField:@"Connection"];
        [request setValue:@"0" forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"iOS UPnP/1.1 ConnectSDK" forHTTPHeaderField:@"USER-AGENT"];

        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *_response, NSData *data, NSError *connectionError) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)_response;

            if (connectionError || !response)
                return;

            if (response.statusCode == 200)
            {
                NSString *sessionId = response.allHeaderFields[@"SID"];

                if (sessionId)
                    _httpServerSessionIds[serviceId] = sessionId;

                [self performSelector:@selector(resubscribeSubscriptions) withObject:nil afterDelay:kSubscriptionTimeoutSeconds / 2];
            }
        }];
    }];
}

- (void) resubscribeSubscriptions
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resubscribeSubscriptions) object:nil];

    [_serviceDescription.serviceList enumerateObjectsUsingBlock:^(id service, NSUInteger idx, BOOL *stop) {
        NSString *serviceId = service[@"serviceId"][@"text"];
        NSString *eventPath = service[@"eventSubURL"][@"text"];
        NSString *commandPath = [NSString stringWithFormat:@"http://%@:%@%@",
                                                           self.serviceDescription.commandURL.host,
                                                           self.serviceDescription.commandURL.port,
                                                           eventPath];
        NSURL *eventSubURL = [NSURL URLWithString:commandPath];

        NSString *timeoutValue = [NSString stringWithFormat:@"Second-%d", kSubscriptionTimeoutSeconds];

        NSString *sessionId = _httpServerSessionIds[serviceId];

        if (!sessionId)
            return;

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:eventSubURL];
        [request setHTTPMethod:@"SUBSCRIBE"];
        [request setValue:timeoutValue forHTTPHeaderField:@"TIMEOUT"];
        [request setValue:sessionId forHTTPHeaderField:@"SID"];

        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *_response, NSData *data, NSError *connectionError) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)_response;

            if (connectionError || !response)
                return;

            if (response.statusCode == 200)
            {
                [self performSelector:@selector(resubscribeSubscriptions) withObject:nil afterDelay:kSubscriptionTimeoutSeconds / 2];
            }
        }];
    }];
}

- (void) unsubscribeServices
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resubscribeSubscriptions) object:nil];

    [_serviceDescription.serviceList enumerateObjectsUsingBlock:^(id service, NSUInteger idx, BOOL *stop) {
        NSString *serviceId = service[@"serviceId"][@"text"];
        NSString *eventPath = service[@"eventSubURL"][@"text"];
        NSString *commandPath = [NSString stringWithFormat:@"http://%@:%@%@",
                                                           self.serviceDescription.commandURL.host,
                                                           self.serviceDescription.commandURL.port,
                                                           eventPath];
        NSURL *eventSubURL = [NSURL URLWithString:commandPath];

        NSString *sessionId = _httpServerSessionIds[serviceId];

        if (!sessionId)
            return;

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:eventSubURL];
        [request setHTTPMethod:@"UNSUBSCRIBE"];
        [request setValue:sessionId forHTTPHeaderField:@"SID"];

        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *_response, NSData *data, NSError *connectionError) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)_response;

            if (connectionError || !response)
                return;

            if (response.statusCode == 200)
            {
                [_httpServerSessionIds removeObjectForKey:serviceId];
            }
        }];
    }];
}

#pragma mark - Media Player

- (id <MediaControl>)mediaControl
{
    return self;
}

- (CapabilityPriorityLevel) mediaControlPriority
{
    return CapabilityPriorityLevelNormal;
}

- (void)playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSString *playXML = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
            "<s:Body>"
            "<u:Play xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
            "<InstanceID>0</InstanceID>"
            "<Speed>1</Speed>"
            "</u:Play>"
            "</s:Body>"
            "</s:Envelope>";

    NSDictionary *playPayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Play\"",
            kDataFieldName : playXML
    };

    ServiceCommand *playCommand = [[ServiceCommand alloc] initWithDelegate:self target:_avTransportControlURL payload:playPayload];
    playCommand.callbackComplete = ^(NSDictionary *responseDic){
        if (success)
            success(nil);
    };
    playCommand.callbackError = failure;
    [playCommand send];
}

- (void)pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSString *xml = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
    "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
    "<s:Body>"
    "<u:Pause xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
    "<InstanceID>0</InstanceID>"
    "</u:Pause>"
    "</s:Body>"
    "</s:Envelope>";
    
    NSDictionary *payload = @{
                                  kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Pause\"",
                                  kDataFieldName : xml
                                  };
    
    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:_avTransportControlURL payload:payload];
    command.callbackComplete = ^(NSDictionary *responseDic){
        if (success)
            success(nil);
    };
    command.callbackError = failure;
    [command send];
}

- (void)stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSString *stopXML = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
    "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
    "<s:Body>"
    "<u:Stop xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
    "<InstanceID>0</InstanceID>"
    "</u:Stop>"
    "</s:Body>"
    "</s:Envelope>";
    
    NSDictionary *stopPayload = @{
                                  kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Stop\"",
                                  kDataFieldName : stopXML
                                  };
    
    ServiceCommand *stopCommand = [[ServiceCommand alloc] initWithDelegate:self target:_avTransportControlURL payload:stopPayload];
    stopCommand.callbackComplete = ^(NSDictionary *responseDic){
        if (success)
            success(nil);
    };
    stopCommand.callbackError = failure;
    [stopCommand send];
}

- (void)rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([ConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSString *timeString = [self stringForTime:position];

    NSString *commandXML = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
            "<s:Body>"
            "<u:Seek xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
            "<InstanceID>0</InstanceID>"
            "<Unit>REL_TIME</Unit>"
            "<Target>%@</Target>"
            "</u:Seek>"
            "</s:Body>"
            "</s:Envelope>",
            timeString
    ];

    NSDictionary *commandPayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Seek\"",
            kDataFieldName : commandXML
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:_avTransportControlURL payload:commandPayload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    NSString *commandXML = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
            "<s:Body>"
            "<u:GetTransportInfo xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
            "<InstanceID>0</InstanceID>"
            "</u:GetTransportInfo>"
            "</s:Body>"
            "</s:Envelope>";

    NSDictionary *commandPayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#GetTransportInfo\"",
            kDataFieldName : commandXML
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:_avTransportControlURL payload:commandPayload];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        NSDictionary *response = [[[responseObject objectForKey:@"s:Envelope"] objectForKey:@"s:Body"] objectForKey:@"u:GetTransportInfoResponse"];
        NSString *transportState = [[[response objectForKey:@"CurrentTransportState"] objectForKey:@"text"] uppercaseString];

        MediaControlPlayState playState = MediaControlPlayStateUnknown;
        
        if ([transportState isEqualToString:@"STOPPED"])
            playState = MediaControlPlayStateFinished;
        else if ([transportState isEqualToString:@"PAUSED_PLAYBACK"])
            playState = MediaControlPlayStatePaused;
        else if ([transportState isEqualToString:@"PAUSED_RECORDING"])
            playState = MediaControlPlayStateUnknown;
        else if ([transportState isEqualToString:@"PLAYING"])
            playState = MediaControlPlayStatePlaying;
        else if ([transportState isEqualToString:@"RECORDING"])
            playState = MediaControlPlayStateUnknown;
        else if ([transportState isEqualToString:@"TRANSITIONING"])
            playState = MediaControlPlayStateIdle;
        else if ([transportState isEqualToString:@"NO_MEDIA_PRESENT"])
            playState = MediaControlPlayStateIdle;

        if (success)
            success(playState);
    };
    command.callbackError = failure;
    [command send];
}

- (void)getDurationWithSuccess:(MediaDurationSuccessBlock)success failure:(FailureBlock)failure
{
    [self getPositionInfoWithSuccess:^(NSDictionary *responseObject)
    {
        NSDictionary *response = [[[responseObject objectForKey:@"s:Envelope"] objectForKey:@"s:Body"] objectForKey:@"u:GetPositionInfoResponse"];
        NSString *durationString = [[response objectForKey:@"TrackDuration"] objectForKey:@"text"];
        NSTimeInterval duration = [self timeForString:durationString];
        if (success)
            success(duration);
    } failure:failure];
}

- (void)getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{
    [self getPositionInfoWithSuccess:^(NSDictionary *responseObject)
    {
        NSDictionary *response = [[[responseObject objectForKey:@"s:Envelope"] objectForKey:@"s:Body"] objectForKey:@"u:GetPositionInfoResponse"];
        NSString *currentTimeString = [[response objectForKey:@"RelTime"] objectForKey:@"text"];
        NSTimeInterval currentTime = [self timeForString:currentTimeString];

        if (success)
            success(currentTime);
    } failure:failure];
}

- (ServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    [self getPlayStateWithSuccess:success failure:failure];

    SuccessBlock successBlock = ^(NSDictionary *responseObject) {
        
        NSDictionary *response = responseObject[@"Event"][@"InstanceID"];
        NSString *transportState = response[@"TransportState"][@"val"];

        MediaControlPlayState playState = MediaControlPlayStateUnknown;

        if ([transportState isEqualToString:@"STOPPED"])
            playState = MediaControlPlayStateFinished;
        else if ([transportState isEqualToString:@"PAUSED_PLAYBACK"])
            playState = MediaControlPlayStatePaused;
        else if ([transportState isEqualToString:@"PAUSED_RECORDING"])
            playState = MediaControlPlayStateUnknown;
        else if ([transportState isEqualToString:@"PLAYING"])
            playState = MediaControlPlayStatePlaying;
        else if ([transportState isEqualToString:@"RECORDING"])
            playState = MediaControlPlayStateUnknown;
        else if ([transportState isEqualToString:@"TRANSITIONING"])
            playState = MediaControlPlayStateIdle;
        else if ([transportState isEqualToString:@"NO_MEDIA_PRESENT"])
            playState = MediaControlPlayStateIdle;

        if (success && transportState)
            success(playState);
    };

    ServiceSubscription *subscription = [ServiceSubscription subscriptionWithDelegate:self target:_avTransportEventURL payload:nil callId:-1];
    [subscription addSuccess:successBlock];
    [subscription addFailure:failure];
    [subscription subscribe];
    return subscription;
}

- (void) getPositionInfoWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSString *commandXML = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
            "<s:Body>"
            "<u:GetPositionInfo xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
            "<InstanceID>0</InstanceID>"
            "</u:GetPositionInfo>"
            "</s:Body>"
            "</s:Envelope>";

    NSDictionary *commandPayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#GetPositionInfo\"",
            kDataFieldName : commandXML
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:_avTransportControlURL payload:commandPayload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getMediaMetaDataWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getPositionInfoWithSuccess:^(NSDictionary *responseObject)
     {
         NSDictionary *response = [[[responseObject objectForKey:@"s:Envelope"] objectForKey:@"s:Body"] objectForKey:@"u:GetPositionInfoResponse"];
         NSString *metaDataString = [[response objectForKey:@"TrackMetaData"] objectForKey:@"text"];
         if(metaDataString){
             if (success)
                 success([self getMetaDataDictionary:metaDataString]);
            }
     } failure:failure];
}

- (ServiceSubscription *)subscribeMediaInfoWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self getMediaMetaDataWithSuccess:success failure:failure];
    
    SuccessBlock successBlock = ^(NSDictionary *responseObject) {
        
        NSDictionary *response = responseObject[@"Event"][@"InstanceID"];
        NSString *currentTrackMetaData = response[@"CurrentTrackMetaData"][@"val"];
        
        if(currentTrackMetaData){
            if (success)
                success([self getMetaDataDictionary:currentTrackMetaData]);
        }
    };
    
    ServiceSubscription *subscription = [ServiceSubscription subscriptionWithDelegate:self target:_avTransportEventURL payload:nil callId:-1];
    [subscription addSuccess:successBlock];
    [subscription addFailure:failure];
    [subscription subscribe];
    return subscription;
}

- (NSTimeInterval) timeForString:(NSString *)timeString
{
    if (!timeString || [timeString isEqualToString:@""])
        return 0;

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:m:ss"];

    NSDate *time = [formatter dateFromString:timeString];
    NSDate *midnight = [formatter dateFromString:@"00:00:00"];

    NSTimeInterval timeInterval = [time timeIntervalSinceDate:midnight];

    if (timeInterval < 0)
        timeInterval = 0;

    return timeInterval;
}

- (NSString *) stringForTime:(NSTimeInterval)timeInterval
{
    int time = (int) round(timeInterval);

    int second = time % 60;
    int minute = (time / 60) % 60;
    int hour = time / 3600;

    NSString *timeString = [NSString stringWithFormat:@"%02d:%02d:%02d", hour, minute, second];

    return timeString;
}

-(NSDictionary*)getMetaDataDictionary:(NSString *)metaDataXML{
    
    NSError *xmlError;
    NSDictionary *mediaMetadataResponse = [[[CTXMLReader dictionaryForXMLString:metaDataXML error:&xmlError] objectForKey:@"DIDL-Lite"] objectForKey:@"item"];
    
    NSMutableDictionary *mediaMetaData = [NSMutableDictionary dictionary];
    
    if([mediaMetadataResponse objectForKey:@"dc:title"])
        [mediaMetaData setObject:[[mediaMetadataResponse objectForKey:@"dc:title"] objectForKey:@"text"] forKey:@"title"];
    
    if([mediaMetadataResponse objectForKey:@"r:albumArtist"])
        [mediaMetaData setObject:[[mediaMetadataResponse objectForKey:@"r:albumArtist"] objectForKey:@"text"] forKey:@"subtitle"];
    
    if([mediaMetadataResponse objectForKey:@"dc:description"])
        [mediaMetaData setObject:[[mediaMetadataResponse objectForKey:@"dc:description"] objectForKey:@"text"] forKey:@"subtitle"];
    
    if([mediaMetadataResponse objectForKey:@"upnp:albumArtURI"])
        [mediaMetaData setObject:[[mediaMetadataResponse objectForKey:@"upnp:albumArtURI"] objectForKey:@"text"] forKey:@"iconURL"];
    
    return mediaMetaData;
}

#pragma mark - Media Player

- (id <MediaPlayer>)mediaPlayer
{
    return self;
}

- (CapabilityPriorityLevel) mediaPlayerPriority
{
    return CapabilityPriorityLevelNormal;
}

- (void)displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    NSString *shareXML = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>"
                                                            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                                                            "<s:Body>"
                                                            "<u:SetAVTransportURI xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
                                                            "<InstanceID>0</InstanceID>"
                                                            "<CurrentURI>%@</CurrentURI>"
                                                            "<CurrentURIMetaData>"
                                                            "&lt;DIDL-Lite xmlns=&quot;urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/&quot; xmlns:upnp=&quot;urn:schemas-upnp-org:metadata-1-0/upnp/&quot; xmlns:dc=&quot;http://purl.org/dc/elements/1.1/&quot;&gt;&lt;item id=&quot;1000&quot; parentID=&quot;0&quot; restricted=&quot;0&quot;&gt;&lt;dc:title&gt;%@&lt;/dc:title&gt;&lt;res protocolInfo=&quot;http-get:*:%@:DLNA.ORG_OP=01&quot;&gt;%@&lt;/res&gt;&lt;upnp:class&gt;object.item.imageItem&lt;/upnp:class&gt;&lt;/item&gt;&lt;/DIDL-Lite&gt;"
                                                            "</CurrentURIMetaData>"
                                                            "</u:SetAVTransportURI>"
                                                            "</s:Body>"
                                                            "</s:Envelope>",
                                                    imageURL.absoluteString, title, mimeType, imageURL.absoluteString];
    NSDictionary *sharePayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI\"",
            kDataFieldName : shareXML
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:_avTransportControlURL payload:sharePayload];
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        [self playWithSuccess:^(id responseObject) {
            if (success)
            {
                LaunchSession *launchSession = [LaunchSession new];
                launchSession.sessionType = LaunchSessionTypeMedia;
                launchSession.service = self;
                
                success(launchSession, self.mediaControl);
            }
        } failure:failure];
    };

    command.callbackError = failure;
    [command send];
}

- (void) displayImage:(MediaInfo *)mediaInfo
              success:(MediaPlayerDisplaySuccessBlock)success
              failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    [self displayImage:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType success:success failure:failure];
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    NSArray *mediaElements = [mimeType componentsSeparatedByString:@"/"];
    NSString *mediaType = mediaElements[0];
    NSString *mediaFormat = mediaElements[1];

    if (!mediaType || mediaType.length == 0 || !mediaFormat || mediaFormat.length == 0)
    {
        if (failure)
            failure([ConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid mimeType (audio/*, video/*, etc"]);

        return;
    }

    mediaFormat = [mediaFormat isEqualToString:@"mp3"] ? @"mpeg" : mediaFormat;
    mimeType = [NSString stringWithFormat:@"%@/%@", mediaType, mediaFormat];

    NSString *shareXML = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>"
                                                            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                                                            "<s:Body>"
                                                            "<u:SetAVTransportURI xmlns:u=\"urn:schemas-upnp-org:service:AVTransport:1\">"
                                                            "<InstanceID>0</InstanceID>"
                                                            "<CurrentURI>%@</CurrentURI>"
                                                            "<CurrentURIMetaData>"
                                                            "&lt;DIDL-Lite xmlns=&quot;urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/&quot; xmlns:upnp=&quot;urn:schemas-upnp-org:metadata-1-0/upnp/&quot; xmlns:dc=&quot;http://purl.org/dc/elements/1.1/&quot;&gt;&lt;item id=&quot;0&quot; parentID=&quot;0&quot; restricted=&quot;0&quot;&gt;&lt;dc:title&gt;%@&lt;/dc:title&gt;&lt;dc:description&gt;%@&lt;/dc:description&gt;&lt;res protocolInfo=&quot;http-get:*:%@:DLNA.ORG_PN=MP3;DLNA.ORG_OP=01;DLNA.ORG_FLAGS=01500000000000000000000000000000&quot;&gt;%@&lt;/res&gt;&lt;upnp:albumArtURI&gt;%@&lt;/upnp:albumArtURI&gt;&lt;upnp:class&gt;object.item.%@Item&lt;/upnp:class&gt;&lt;/item&gt;&lt;/DIDL-Lite&gt;"
                                                            "</CurrentURIMetaData>"
                                                            "</u:SetAVTransportURI>"
                                                            "</s:Body>"
                                                            "</s:Envelope>",
                                                    mediaURL.absoluteString, title, description, mimeType, mediaURL.absoluteString, iconURL.absoluteString, mediaType];
    NSDictionary *sharePayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI\"",
            kDataFieldName : shareXML
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:_avTransportControlURL payload:sharePayload];
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        [self playWithSuccess:^(id responseObject) {
            if (success)
            {
                LaunchSession *launchSession = [LaunchSession new];
                launchSession.sessionType = LaunchSessionTypeMedia;
                launchSession.service = self;
                
                success(launchSession, self.mediaControl);
            }
        } failure:failure];
    };

    command.callbackError = failure;
    [command send];
}

- (void) playMedia:(MediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        ImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    [self playMedia:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType shouldLoop:shouldLoop success:success failure:failure];
}

- (void)closeMedia:(LaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.mediaControl stopWithSuccess:success failure:failure];
}

#pragma mark - Volume

- (id <VolumeControl>) volumeControl
{
    return self;
}

- (CapabilityPriorityLevel) volumeControlPriority
{
    return CapabilityPriorityLevelNormal;
}

- (void) volumeUpWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.volumeControl getVolumeWithSuccess:^(float volume) {
        if (volume < 1.0)
            [self.volumeControl setVolume:(float) (volume + 0.01) success:success failure:failure];
        else
        {
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Volume is already at max"]);
        }
    } failure:failure];
}

- (void) volumeDownWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.volumeControl getVolumeWithSuccess:^(float volume) {
        if (volume > 0.0)
            [self.volumeControl setVolume:(float) (volume - 0.01) success:success failure:failure];
        else
        {
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Volume is already at 0"]);
        }
    } failure:failure];
}

- (void) getVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure
{
    NSString *commandXML = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
            "<s:Body>"
            "<u:GetVolume xmlns:u=\"urn:schemas-upnp-org:service:RenderingControl:1\">"
            "<InstanceID>0</InstanceID>"
            "<Channel>Master</Channel>"
            "</u:GetVolume>"
            "</s:Body>"
            "</s:Envelope>";

    NSDictionary *commandPayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:RenderingControl:1#GetVolume\"",
            kDataFieldName : commandXML
    };

    SuccessBlock successBlock = ^(NSDictionary *responseXML) {
        int volume = -1;

        volume = [responseXML[@"s:Envelope"][@"s:Body"][@"u:GetVolumeResponse"][@"CurrentVolume"][@"text"] intValue];

        if (volume == -1)
        {
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not find volume information in response"]);
        } else
        {
            if (success)
                success((float) volume / 100.0f);
        }
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:_renderingControlControlURL payload:commandPayload];
    command.callbackComplete = successBlock;
    command.callbackError = failure;
    [command send];
}

- (void) setVolume:(float)volume success:(SuccessBlock)success failure:(FailureBlock)failure
{
    int targetVolume = (int) round(volume * 100);

    NSString *commandXML = [NSString stringWithFormat: @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
            "<s:Body>"
            "<u:SetVolume xmlns:u=\"urn:schemas-upnp-org:service:RenderingControl:1\">"
            "<InstanceID>0</InstanceID>"
            "<Channel>Master</Channel>"
            "<DesiredVolume>%d</DesiredVolume>"
            "</u:SetVolume>"
            "</s:Body>"
            "</s:Envelope>", targetVolume];

    NSDictionary *commandPayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:RenderingControl:1#SetVolume\"",
            kDataFieldName : commandXML
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:_renderingControlControlURL payload:commandPayload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (ServiceSubscription *) subscribeVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure
{
    [self.volumeControl getVolumeWithSuccess:success failure:failure];

    SuccessBlock successBlock = ^(NSDictionary *responseObject) {
        const NSInteger masterVolume = [self valueForVolumeKey:@"Volume"
                                                     atChannel:@"Master"
                                                    inResponse:responseObject];

        if (masterVolume == kValueNotFound)
        {
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not find volume in subscription response"]);
        } else
        {
            if (success)
                success((float) masterVolume / 100.0f);
        }
    };

    ServiceSubscription *subscription = [ServiceSubscription subscriptionWithDelegate:self target:_renderingControlEventURL payload:nil callId:-1];
    [subscription addSuccess:successBlock];
    [subscription addFailure:failure];
    [subscription subscribe];
    return subscription;
}

- (void) getMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure
{
    NSString *commandXML = @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
            "<s:Body>"
            "<u:GetMute xmlns:u=\"urn:schemas-upnp-org:service:RenderingControl:1\">"
            "<InstanceID>0</InstanceID>"
            "<Channel>Master</Channel>"
            "</u:GetMute>"
            "</s:Body>"
            "</s:Envelope>";

    NSDictionary *commandPayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:RenderingControl:1#GetMute\"",
            kDataFieldName : commandXML
    };

    SuccessBlock successBlock = ^(NSDictionary *responseXML) {
        int mute = -1;

        mute = [responseXML[@"s:Envelope"][@"s:Body"][@"u:GetMuteResponse"][@"CurrentMute"][@"text"] intValue];

        if (mute == -1)
        {
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not find mute information in response"]);
        } else
        {
            if (success)
                success((BOOL) mute);
        }
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:_renderingControlControlURL payload:commandPayload];
    command.callbackComplete = successBlock;
    command.callbackError = failure;
    [command send];
}

- (void) setMute:(BOOL)mute success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSString *commandXML = [NSString stringWithFormat: @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
            "<s:Envelope s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\">"
            "<s:Body>"
            "<u:SetMute xmlns:u=\"urn:schemas-upnp-org:service:RenderingControl:1\">"
            "<InstanceID>0</InstanceID>"
            "<Channel>Master</Channel>"
            "<DesiredMute>%d</DesiredMute>"
            "</u:SetMute>"
            "</s:Body>"
            "</s:Envelope>", mute];

    NSDictionary *commandPayload = @{
            kActionFieldName : @"\"urn:schemas-upnp-org:service:RenderingControl:1#SetMute\"",
            kDataFieldName : commandXML
    };

    ServiceCommand *command = [[ServiceCommand alloc] initWithDelegate:self target:_renderingControlControlURL payload:commandPayload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (ServiceSubscription *) subscribeMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure
{
    [self.volumeControl getMuteWithSuccess:success failure:failure];

    SuccessBlock successBlock = ^(NSDictionary *responseObject) {
        const NSInteger masterMute = [self valueForVolumeKey:@"Mute"
                                                   atChannel:@"Master"
                                                  inResponse:responseObject];

        if (masterMute == kValueNotFound)
        {
            if (failure)
                failure([ConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Could not find mute in subscription response"]);
        } else
        {
            if (success)
                success((BOOL) masterMute);
        }
    };

    ServiceSubscription *subscription = [ServiceSubscription subscriptionWithDelegate:self target:_renderingControlEventURL payload:nil callId:-1];
    [subscription addSuccess:successBlock];
    [subscription addFailure:failure];
    [subscription subscribe];
    return subscription;
}

@end
