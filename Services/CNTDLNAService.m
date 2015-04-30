//
//  CNTDLNAService.m
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

#import "CNTDLNAService_Private.h"
#import "CNTConnectError.h"
#import "CTXMLReader.h"
#import "CNTConnectUtil.h"
#import "CNTDeviceServiceReachability.h"
#import "CNTDLNAHTTPServer.h"

#import "NSDictionary+CNTKeyPredicateSearch.h"
#import "NSString+CNTCommon.h"
#import "XMLWriter+CNTConvenienceMethods.h"

NSString *const kCNTDataFieldName = @"XMLData";
#define kActionFieldName @"SOAPAction"
#define kSubscriptionTimeoutSeconds 300


static NSString *const kAVTransportNamespace = @"urn:schemas-upnp-org:service:AVTransport:1";
static NSString *const kRenderingControlNamespace = @"urn:schemas-upnp-org:service:RenderingControl:1";

static NSString *const kDIDLLiteNamespace = @"urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/";
static NSString *const kUPNPNamespace = @"urn:schemas-upnp-org:metadata-1-0/upnp/";
static NSString *const kDCNamespace = @"http://purl.org/dc/elements/1.1/";

static const NSInteger kValueNotFound = -1;


@interface CNTDLNAService () <CNTServiceCommandDelegate, CNTDeviceServiceReachabilityDelegate>
{
//    NSOperationQueue *_commandQueue;
    CNTDLNAHTTPServer *_httpServer;
    NSMutableDictionary *_httpServerSessionIds;

    CNTDeviceServiceReachability *_serviceReachability;
}

@end

@implementation CNTDLNAService

@synthesize serviceDescription = _serviceDescription;

- (void) updateCapabilities
{
    NSArray *capabilities = @[
        kCNTMediaPlayerDisplayImage,
        kCNTMediaPlayerPlayVideo,
        kCNTMediaPlayerPlayAudio,
        kCNTMediaPlayerPlayPlaylist,
        kCNTMediaPlayerClose,
        kCNTMediaPlayerMetaDataTitle,
        kCNTMediaPlayerMetaDataMimeType,
        kCNTMediaControlPlay,
        kCNTMediaControlPause,
        kCNTMediaControlStop,
        kCNTMediaControlSeek,
        kCNTMediaControlPosition,
        kCNTMediaControlDuration,
        kCNTMediaControlPlayState,
        kCNTMediaControlPlayStateSubscribe,
        kCNTMediaControlMetadata,
        kCNTMediaControlMetadataSubscribe,
        kCNTPlayListControlNext,
        kCNTPlayListControlPrevious,
        kCNTPlayListControlJumpTrack
    ];

    capabilities = [capabilities arrayByAddingObjectsFromArray:kCNTVolumeControlCapabilities];

    [self setCapabilities:capabilities];
}

+ (NSDictionary *) discoveryParameters
{
    return @{
            @"serviceId": kCNTConnectSDKDLNAServiceId,
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

#pragma mark - Getters & Setters

/// Returns the set delegate property value or self.
- (id<CNTServiceCommandDelegate>)serviceCommandDelegate {
    return _serviceCommandDelegate ?: self;
}

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

- (void)setServiceDescription:(CNTServiceDescription *)serviceDescription
{
    _serviceDescription = serviceDescription;
    
    if (_serviceDescription.locationXML)
    {
        [self updateControlURLs];

        if (!_httpServer)
            _httpServer = [self createDLNAHTTPServer];
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
        NSURL *controlURL = [self serviceURLForPath:controlPath];
        NSURL *eventURL = [self serviceURLForPath:eventPath];
       
        if ([serviceName rangeOfString:@":AVTransport"].location != NSNotFound)
        {
            _avTransportControlURL = controlURL;
            _avTransportEventURL = eventURL;
        } else if ([serviceName rangeOfString:@":RenderingControl"].location != NSNotFound)
        {
            _renderingControlControlURL = controlURL;
            _renderingControlEventURL = eventURL;
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

    _serviceReachability = [self createDeviceServiceReachabilityWithTargetURL:_avTransportControlURL];
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

    [self unsubscribeServices];
    [_httpServer stop];
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

/// Builds a request XML for the given command name. Prepares the outer, common
/// XML and the @c writerBlock is called to add any extra information to the XML.
- (NSString *)commandXMLForCommandName:(NSString *)commandName
                      commandNamespace:(NSString *)namespace
                        andWriterBlock:(void (^)(XMLWriter *writer))writerBlock {
    NSParameterAssert(commandName);

    XMLWriter *writer = [XMLWriter new];
    [writer writeStartDocumentWithEncodingAndVersion:@"UTF-8" version:@"1.0"];

    static NSString *const kSOAPNamespace = @"http://schemas.xmlsoap.org/soap/envelope/";

    [writer setPrefix:@"s" namespaceURI:kSOAPNamespace];
    [writer setPrefix:@"u" namespaceURI:namespace];

    [writer writeElement:@"Envelope" withNamespace:kSOAPNamespace andContentsBlock:^(XMLWriter *writer) {
        [writer writeAttribute:@"s:encodingStyle" value:@"http://schemas.xmlsoap.org/soap/encoding/"];
        [writer writeElement:@"Body" withNamespace:kSOAPNamespace andContentsBlock:^(XMLWriter *writer) {
            [writer writeElement:commandName withNamespace:namespace andContentsBlock:^(XMLWriter *writer) {
                [writer writeAttribute:@"xmlns:u" value:namespace];
                [writer writeElement:@"InstanceID" withContents:@"0"];

                if (writerBlock) {
                    writerBlock(writer);
                }
            }];
        }];
    }];

    return [writer toString];
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

- (int) sendCommand:(CNTServiceCommand *)command withPayload:(NSDictionary *)payload toURL:(NSURL *)URL
{
    NSString *actionField = [payload objectForKey:kActionFieldName];
    NSString *xml = [payload objectForKey:kCNTDataFieldName];

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
                dispatch_on_main(^{ command.callbackError([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Could not parse command response"]); });
        } else
        {
            NSDictionary *upnpFault = [self responseDataFromResponse:dataXML
                                                           forMethod:@"Fault"];

            if (upnpFault)
            {
                NSString *errorDescription = [[[[upnpFault objectForKey:@"detail"] objectForKeyEndingWithString:@":UPnPError"] objectForKeyEndingWithString:@":errorDescription"] objectForKey:@"text"];

                if (!errorDescription)
                    errorDescription = @"Unknown UPnP error";

                if (command.callbackError)
                    dispatch_on_main(^{ command.callbackError([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeTvError andDetails:errorDescription]); });
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

- (int) sendSubscription:(CNTServiceSubscription *)subscription type:(CNTServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    if (type == CNTServiceSubscriptionTypeSubscribe)
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
        NSURL *eventSubURL = [self serviceURLForPath:eventPath];
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
        NSURL *eventSubURL = [self serviceURLForPath:eventPath];

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
        NSURL *eventSubURL = [self serviceURLForPath:eventPath];

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

- (NSURL*)serviceURLForPath:(NSString *)path{
    if(![path hasPrefix:@"/"]){
        path = [NSString stringWithFormat:@"/%@",path];
    }
    NSString *serviceURL = [NSString stringWithFormat:@"http://%@:%@%@",
                      self.serviceDescription.commandURL.host,
                      self.serviceDescription.commandURL.port,
                      path];
    return [NSURL URLWithString:serviceURL];
}

#pragma mark - Media Player

- (id <CNTMediaControl>)mediaControl
{
    return self;
}

- (CNTCapabilityPriorityLevel) mediaControlPriority
{
    return CNTCapabilityPriorityLevelNormal;
}

- (void)playWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *playXML = [self commandXMLForCommandName:@"Play"
                                      commandNamespace:kAVTransportNamespace
                                        andWriterBlock:^(XMLWriter *writer) {
                                            [writer writeElement:@"Speed" withContents:@"1"];
                                        }];
    NSDictionary *playPayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Play\"",
            kCNTDataFieldName : playXML};

    CNTServiceCommand *playCommand = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_avTransportControlURL payload:playPayload];
    playCommand.callbackComplete = ^(NSDictionary *responseDic){
        if (success)
            success(nil);
    };
    playCommand.callbackError = failure;
    [playCommand send];
}

- (void)pauseWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *pauseXML = [self commandXMLForCommandName:@"Pause"
                                      commandNamespace:kAVTransportNamespace
                                         andWriterBlock:nil];
    NSDictionary *pausePayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Pause\"",
            kCNTDataFieldName : pauseXML};

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_avTransportControlURL payload:pausePayload];
    command.callbackComplete = ^(NSDictionary *responseDic){
        if (success)
            success(nil);
    };
    command.callbackError = failure;
    [command send];
}

- (void)stopWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *stopXML = [self commandXMLForCommandName:@"Stop"
                                      commandNamespace:kAVTransportNamespace
                                        andWriterBlock:nil];
    NSDictionary *stopPayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Stop\"",
            kCNTDataFieldName : stopXML};
    
    CNTServiceCommand *stopCommand = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_avTransportControlURL payload:stopPayload];
    stopCommand.callbackComplete = ^(NSDictionary *responseDic){
        if (success)
            success(nil);
    };
    stopCommand.callbackError = failure;
    [stopCommand send];
}

- (void)rewindWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)fastForwardWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)seek:(NSTimeInterval)position success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *timeString = [self stringForTime:position];
    NSString *seekXML = [self commandXMLForCommandName:@"Seek"
                                      commandNamespace:kAVTransportNamespace
                                        andWriterBlock:^(XMLWriter *writer) {
                                            [writer writeElement:@"Unit" withContents:@"REL_TIME"];
                                            [writer writeElement:@"Target" withContents:timeString];
                                        }];
    NSDictionary *seekPayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Seek\"",
            kCNTDataFieldName : seekXML};

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_avTransportControlURL payload:seekPayload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getPlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *getPlayStateXML = [self commandXMLForCommandName:@"GetTransportInfo"
                                              commandNamespace:kAVTransportNamespace
                                                andWriterBlock:nil];
    NSDictionary *getPlayStatePayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#GetTransportInfo\"",
            kCNTDataFieldName : getPlayStateXML};

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_avTransportControlURL payload:getPlayStatePayload];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        NSDictionary *response = [self responseDataFromResponse:responseObject
                                                      forMethod:@"GetTransportInfoResponse"];
        NSString *transportState = [[[response objectForKey:@"CurrentTransportState"] objectForKey:@"text"] uppercaseString];

        CNTMediaControlPlayState playState = CNTMediaControlPlayStateUnknown;
        
        if ([transportState isEqualToString:@"STOPPED"])
            playState = CNTMediaControlPlayStateFinished;
        else if ([transportState isEqualToString:@"PAUSED_PLAYBACK"])
            playState = CNTMediaControlPlayStatePaused;
        else if ([transportState isEqualToString:@"PAUSED_RECORDING"])
            playState = CNTMediaControlPlayStateUnknown;
        else if ([transportState isEqualToString:@"PLAYING"])
            playState = CNTMediaControlPlayStatePlaying;
        else if ([transportState isEqualToString:@"RECORDING"])
            playState = CNTMediaControlPlayStateUnknown;
        else if ([transportState isEqualToString:@"TRANSITIONING"])
            playState = CNTMediaControlPlayStateIdle;
        else if ([transportState isEqualToString:@"NO_MEDIA_PRESENT"])
            playState = CNTMediaControlPlayStateIdle;

        if (success)
            success(playState);
    };
    command.callbackError = failure;
    [command send];
}

- (void)getDurationWithSuccess:(CNTMediaDurationSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self getPositionInfoWithSuccess:^(NSDictionary *responseObject)
    {
        NSDictionary *response = [self responseDataFromResponse:responseObject
                                                      forMethod:@"GetPositionInfoResponse"];
        NSString *durationString = [[response objectForKey:@"TrackDuration"] objectForKey:@"text"];
        NSTimeInterval duration = [self timeForString:durationString];
        if (success)
            success(duration);
    } failure:failure];
}

- (void)getPositionWithSuccess:(CNTMediaPositionSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self getPositionInfoWithSuccess:^(NSDictionary *responseObject)
    {
        NSDictionary *response = [self responseDataFromResponse:responseObject
                                                      forMethod:@"GetPositionInfoResponse"];
        NSString *currentTimeString = [[response objectForKey:@"RelTime"] objectForKey:@"text"];
        NSTimeInterval currentTime = [self timeForString:currentTimeString];

        if (success)
            success(currentTime);
    } failure:failure];
}

- (CNTServiceSubscription *)subscribePlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self getPlayStateWithSuccess:success failure:failure];

    CNTSuccessBlock successBlock = ^(NSDictionary *responseObject) {
        
        NSDictionary *response = responseObject[@"Event"][@"InstanceID"];
        NSString *transportState = response[@"TransportState"][@"val"];

        CNTMediaControlPlayState playState = CNTMediaControlPlayStateUnknown;

        if ([transportState isEqualToString:@"STOPPED"])
            playState = CNTMediaControlPlayStateFinished;
        else if ([transportState isEqualToString:@"PAUSED_PLAYBACK"])
            playState = CNTMediaControlPlayStatePaused;
        else if ([transportState isEqualToString:@"PAUSED_RECORDING"])
            playState = CNTMediaControlPlayStateUnknown;
        else if ([transportState isEqualToString:@"PLAYING"])
            playState = CNTMediaControlPlayStatePlaying;
        else if ([transportState isEqualToString:@"RECORDING"])
            playState = CNTMediaControlPlayStateUnknown;
        else if ([transportState isEqualToString:@"TRANSITIONING"])
            playState = CNTMediaControlPlayStateIdle;
        else if ([transportState isEqualToString:@"NO_MEDIA_PRESENT"])
            playState = CNTMediaControlPlayStateIdle;

        if (success && transportState)
            success(playState);
    };

    CNTServiceSubscription *subscription = [CNTServiceSubscription subscriptionWithDelegate:self target:_avTransportEventURL payload:nil callId:-1];
    [subscription addSuccess:successBlock];
    [subscription addFailure:failure];
    [subscription subscribe];
    return subscription;
}

- (void) getPositionInfoWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *getPositionInfoXML = [self commandXMLForCommandName:@"GetPositionInfo"
                                                 commandNamespace:kAVTransportNamespace
                                                   andWriterBlock:nil];
    NSDictionary *getPositionInfoPayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#GetPositionInfo\"",
            kCNTDataFieldName : getPositionInfoXML};

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_avTransportControlURL payload:getPositionInfoPayload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getMediaMetaDataWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self getPositionInfoWithSuccess:^(NSDictionary *responseObject)
     {
         NSDictionary *response = [self responseDataFromResponse:responseObject
                                                       forMethod:@"GetPositionInfoResponse"];
         NSString *metaDataString = [[response objectForKey:@"TrackMetaData"] objectForKey:@"text"];
         if(metaDataString){
             if (success)
                 success([self parseMetadataDictionaryFromXMLString:metaDataString]);
            }
     } failure:failure];
}

- (CNTServiceSubscription *)subscribeMediaInfoWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self getMediaMetaDataWithSuccess:success failure:failure];
    
    CNTSuccessBlock successBlock = ^(NSDictionary *responseObject) {
        
        NSDictionary *response = responseObject[@"Event"][@"InstanceID"];
        NSString *currentTrackMetaData = response[@"CurrentTrackMetaData"][@"val"];
        
        if(currentTrackMetaData){
            if (success)
                success([self parseMetadataDictionaryFromXMLString:currentTrackMetaData]);
        }
    };
    
    CNTServiceSubscription *subscription = [CNTServiceSubscription subscriptionWithDelegate:self target:_avTransportEventURL payload:nil callId:-1];
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

- (NSDictionary *)parseMetadataDictionaryFromXMLString:(NSString *)metadataXML {
    NSError *xmlError;
    NSDictionary *mediaMetadataResponse = [[[CTXMLReader dictionaryForXMLString:metadataXML error:&xmlError] objectForKey:@"DIDL-Lite"] objectForKey:@"item"];
    // FIXME: check for XML errors
    
    NSMutableDictionary *mediaMetaData = [NSMutableDictionary dictionary];
    
    if([mediaMetadataResponse objectForKey:@"dc:title"])
        [mediaMetaData setObject:[[mediaMetadataResponse objectForKey:@"dc:title"] objectForKey:@"text"] forKey:@"title"];
    
    if([mediaMetadataResponse objectForKey:@"r:albumArtist"])
        [mediaMetaData setObject:[[mediaMetadataResponse objectForKey:@"r:albumArtist"] objectForKey:@"text"] forKey:@"subtitle"];
    
    if([mediaMetadataResponse objectForKey:@"dc:description"])
        [mediaMetaData setObject:[[mediaMetadataResponse objectForKey:@"dc:description"] objectForKey:@"text"] forKey:@"subtitle"];
    
    if([mediaMetadataResponse objectForKey:@"upnp:albumArtURI"]){
        NSString *imageURL = [[mediaMetadataResponse objectForKey:@"upnp:albumArtURI"] objectForKey:@"text"];
        if(![self isValidUrl:imageURL]){
            imageURL = [self serviceURLForPath:imageURL].absoluteString;
        }
        [mediaMetaData setObject:imageURL forKey:@"iconURL"];
    }

    return mediaMetaData;
}

//Checks if the url provided is valid or not
- (BOOL)isValidUrl:(NSString *)urlString
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    return [NSURLConnection canHandleRequest:request];
}

/// Returns a dictionary for the specified method in the given response object.
- (NSDictionary *)responseDataFromResponse:(NSDictionary *)responseObject
                                 forMethod:(NSString *)method {
    NSDictionary *envelopeObject = [responseObject objectForKeyEndingWithString:@":Envelope"];
    NSDictionary *bodyObject = [envelopeObject objectForKeyEndingWithString:@":Body"];
    NSDictionary *responseData = [bodyObject objectForKeyEndingWithString:
                                  [@":" stringByAppendingString:method]];

    return responseData;
}

#pragma mark - Media Player

- (id <CNTMediaPlayer>)mediaPlayer
{
    return self;
}

- (CNTCapabilityPriorityLevel) mediaPlayerPriority
{
    return CNTCapabilityPriorityLevelNormal;
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

- (void) displayImageWithMediaInfo:(CNTMediaInfo *)mediaInfo
                           success:(CNTMediaPlayerSuccessBlock)success
                           failure:(CNTFailureBlock)failure
{
    NSString *mimeType = mediaInfo.mimeType ?: @"";
    NSString *mediaInfoURLString = mediaInfo.url.absoluteString ?: @"";

    NSString *metadataXML = ({
        XMLWriter *writer = [XMLWriter new];

        [writer setPrefix:@"upnp" namespaceURI:kUPNPNamespace];
        [writer setPrefix:@"dc" namespaceURI:kDCNamespace];

        [writer writeElement:@"DIDL-Lite" withContentsBlock:^(XMLWriter *writer) {
            [writer writeAttribute:@"xmlns" value:kDIDLLiteNamespace];
            [writer writeElement:@"item" withContentsBlock:^(XMLWriter *writer) {
                [writer writeAttributes:@{@"id": @"1000",
                                          @"parentID": @"0",
                                          @"restricted": @"0"}];

                if (mediaInfo.title) {
                    [writer writeElement:@"title" withNamespace:kDCNamespace andContents:mediaInfo.title];
                }

                [writer writeElement:@"res" withContentsBlock:^(XMLWriter *writer) {
                    NSString *value = [NSString stringWithFormat:
                                       @"http-get:*:%@:DLNA.ORG_OP=01",
                                       mimeType];
                    [writer writeAttribute:@"protocolInfo" value:value];
                    [writer writeCharacters:mediaInfoURLString];
                }];

                [writer writeElement:@"class" withNamespace:kUPNPNamespace andContents:@"object.item.imageItem"];
            }];
        }];

        [writer toString];
    });

    NSString *setURLXML = [self commandXMLForCommandName:@"SetAVTransportURI"
                                        commandNamespace:kAVTransportNamespace
                                          andWriterBlock:^(XMLWriter *writer) {
                                              [writer writeElement:@"CurrentURI" withContents:mediaInfoURLString];
                                              [writer writeElement:@"CurrentURIMetaData" withContents:[metadataXML orEmpty]];
                                          }];
    NSDictionary *setURLPayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI\"",
            kCNTDataFieldName : setURLXML};

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_avTransportControlURL payload:setURLPayload];
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        [self playWithSuccess:^(id responseObject) {
            if (success)
            {
                CNTLaunchSession *launchSession = [CNTLaunchSession new];
                launchSession.sessionType = CNTLaunchSessionTypeMedia;
                launchSession.service = self;
                CNTMediaLaunchObject *launchObject = [[CNTMediaLaunchObject alloc] initWithLaunchSession:launchSession andMediaControl:self.mediaControl andPlayListControl:self.playListControl];
                success(launchObject);
            }
        } failure:failure];
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
    
    NSArray *mediaElements = [mediaInfo.mimeType componentsSeparatedByString:@"/"];
    NSString *mediaType = mediaElements[0];
    NSString *mediaFormat = mediaElements[1];
    
    if (!mediaType || mediaType.length == 0 || !mediaFormat || mediaFormat.length == 0)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeArgumentError andDetails:@"You must provide a valid mimeType (audio/*, video/*, etc"]);
        
        return;
    }
    
    mediaFormat = [mediaFormat isEqualToString:@"mp3"] ? @"mpeg" : mediaFormat;
    NSString *mimeType = [NSString stringWithFormat:@"%@/%@", mediaType, mediaFormat];
    NSString *mediaInfoURLString = mediaInfo.url.absoluteString ?: @"";

    NSString *metadataXML = ({
        XMLWriter *writer = [XMLWriter new];

        [writer setPrefix:@"upnp" namespaceURI:kUPNPNamespace];
        [writer setPrefix:@"dc" namespaceURI:kDCNamespace];

        [writer writeElement:@"DIDL-Lite" withContentsBlock:^(XMLWriter *writer) {
            [writer writeAttribute:@"xmlns" value:kDIDLLiteNamespace];
            [writer writeElement:@"item" withContentsBlock:^(XMLWriter *writer) {
                [writer writeAttributes:@{@"id": @"0",
                                          @"parentID": @"0",
                                          @"restricted": @"0"}];

                if (mediaInfo.title) {
                    [writer writeElement:@"title" withNamespace:kDCNamespace andContents:mediaInfo.title];
                }
                if (mediaInfo.description) {
                    [writer writeElement:@"description" withNamespace:kDCNamespace andContents:mediaInfo.description];
                }

                [writer writeElement:@"res" withContentsBlock:^(XMLWriter *writer) {
                    NSString *value = [NSString stringWithFormat:
                                       @"http-get:*:%@:DLNA.ORG_PN=MP3;DLNA.ORG_OP=01;DLNA.ORG_FLAGS=01500000000000000000000000000000",
                                       [mimeType orEmpty]];
                    [writer writeAttribute:@"protocolInfo" value:value];
                    [writer writeCharacters:mediaInfoURLString];
                }];

                NSString *iconURLString = iconURL.absoluteString ?: @"";
                [writer writeElement:@"albumArtURI" withNamespace:kUPNPNamespace andContents:iconURLString];
                NSString *classItem = [NSString stringWithFormat:@"object.item.%@Item", [mediaType orEmpty]];
                [writer writeElement:@"class" withNamespace:kUPNPNamespace andContents:classItem];
            }];
        }];

        [writer toString];
    });

    NSString *setURLXML = [self commandXMLForCommandName:@"SetAVTransportURI"
                                        commandNamespace:kAVTransportNamespace
                                          andWriterBlock:^(XMLWriter *writer) {
                                              [writer writeElement:@"CurrentURI" withContents:mediaInfoURLString];
                                              [writer writeElement:@"CurrentURIMetaData" withContents:[metadataXML orEmpty]];
                                          }];
    NSDictionary *setURLPayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#SetAVTransportURI\"",
            kCNTDataFieldName : setURLXML};
    
    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_avTransportControlURL payload:setURLPayload];
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        [self playWithSuccess:^(id responseObject) {
            if (success)
            {
                CNTLaunchSession *launchSession = [CNTLaunchSession new];
                launchSession.sessionType = CNTLaunchSessionTypeMedia;
                launchSession.service = self;
                CNTMediaLaunchObject *launchObject = [[CNTMediaLaunchObject alloc] initWithLaunchSession:launchSession andMediaControl:self.mediaControl andPlayListControl:self.playListControl];
                success(launchObject);
            }
        } failure:failure];
    };
    
    command.callbackError = failure;
    [command send];
    
}

- (void)closeMedia:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.mediaControl stopWithSuccess:success failure:failure];
}

#pragma mark - Volume

- (id <CNTVolumeControl>) volumeControl
{
    return self;
}

- (CNTCapabilityPriorityLevel) volumeControlPriority
{
    return CNTCapabilityPriorityLevelNormal;
}

- (void) volumeUpWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.volumeControl getVolumeWithSuccess:^(float volume) {
        if (volume < 1.0)
            [self.volumeControl setVolume:(float) (volume + 0.01) success:success failure:failure];
        else
        {
            if (failure)
                failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Volume is already at max"]);
        }
    } failure:failure];
}

- (void) volumeDownWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.volumeControl getVolumeWithSuccess:^(float volume) {
        if (volume > 0.0)
            [self.volumeControl setVolume:(float) (volume - 0.01) success:success failure:failure];
        else
        {
            if (failure)
                failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Volume is already at 0"]);
        }
    } failure:failure];
}

- (void) getVolumeWithSuccess:(CNTVolumeSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *getVolumeXML = [self commandXMLForCommandName:@"GetVolume"
                                           commandNamespace:kRenderingControlNamespace
                                             andWriterBlock:^(XMLWriter *writer) {
                                                 [writer writeElement:@"Channel" withContents:@"Master"];
                                             }];
    NSDictionary *getVolumePayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:RenderingControl:1#GetVolume\"",
            kCNTDataFieldName : getVolumeXML};

    CNTSuccessBlock successBlock = ^(NSDictionary *responseXML) {
        int volume = -1;

        volume = [[self responseDataFromResponse:responseXML
                                       forMethod:@"GetVolumeResponse"][@"CurrentVolume"][@"text"] intValue];

        if (volume == -1)
        {
            if (failure)
                failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Could not find volume information in response"]);
        } else
        {
            if (success)
                success((float) volume / 100.0f);
        }
    };

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_renderingControlControlURL payload:getVolumePayload];
    command.callbackComplete = successBlock;
    command.callbackError = failure;
    [command send];
}

- (void) setVolume:(float)volume success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetVolume = [NSString stringWithFormat:@"%d", (int) round(volume * 100)];
    NSString *setVolumeXML = [self commandXMLForCommandName:@"SetVolume"
                                           commandNamespace:kRenderingControlNamespace
                                             andWriterBlock:^(XMLWriter *writer) {
                                                 [writer writeElement:@"Channel" withContents:@"Master"];
                                                 [writer writeElement:@"DesiredVolume" withContents:targetVolume];
                                             }];
    NSDictionary *setVolumePayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:RenderingControl:1#SetVolume\"",
            kCNTDataFieldName : setVolumeXML};

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_renderingControlControlURL payload:setVolumePayload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (CNTServiceSubscription *) subscribeVolumeWithSuccess:(CNTVolumeSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.volumeControl getVolumeWithSuccess:success failure:failure];

    CNTSuccessBlock successBlock = ^(NSDictionary *responseObject) {
        const NSInteger masterVolume = [self valueForVolumeKey:@"Volume"
                                                     atChannel:@"Master"
                                                    inResponse:responseObject];

        if (masterVolume == kValueNotFound)
        {
            if (failure)
                failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Could not find volume in subscription response"]);
        } else
        {
            if (success)
                success((float) masterVolume / 100.0f);
        }
    };

    CNTServiceSubscription *subscription = [CNTServiceSubscription subscriptionWithDelegate:self target:_renderingControlEventURL payload:nil callId:-1];
    [subscription addSuccess:successBlock];
    [subscription addFailure:failure];
    [subscription subscribe];
    return subscription;
}

- (void) getMuteWithSuccess:(CNTMuteSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *getMuteXML = [self commandXMLForCommandName:@"GetMute"
                                         commandNamespace:kRenderingControlNamespace
                                           andWriterBlock:^(XMLWriter *writer) {
                                               [writer writeElement:@"Channel" withContents:@"Master"];
                                           }];
    NSDictionary *getMutePayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:RenderingControl:1#GetMute\"",
            kCNTDataFieldName : getMuteXML};

    CNTSuccessBlock successBlock = ^(NSDictionary *responseXML) {
        int mute = -1;

        mute = [[self responseDataFromResponse:responseXML
                                     forMethod:@"GetMuteResponse"][@"CurrentMute"][@"text"] intValue];

        if (mute == -1)
        {
            if (failure)
                failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Could not find mute information in response"]);
        } else
        {
            if (success)
                success((BOOL) mute);
        }
    };

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_renderingControlControlURL payload:getMutePayload];
    command.callbackComplete = successBlock;
    command.callbackError = failure;
    [command send];
}

- (void) setMute:(BOOL)mute success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetMute = [NSString stringWithFormat:@"%d", mute];
    NSString *setMuteXML = [self commandXMLForCommandName:@"SetMute"
                                         commandNamespace:kRenderingControlNamespace
                                           andWriterBlock:^(XMLWriter *writer) {
                                               [writer writeElement:@"Channel" withContents:@"Master"];
                                               [writer writeElement:@"DesiredMute" withContents:targetMute];
                                           }];
    NSDictionary *setMutePayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:RenderingControl:1#SetMute\"",
            kCNTDataFieldName : setMuteXML};

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_renderingControlControlURL payload:setMutePayload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (CNTServiceSubscription *) subscribeMuteWithSuccess:(CNTMuteSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.volumeControl getMuteWithSuccess:success failure:failure];

    CNTSuccessBlock successBlock = ^(NSDictionary *responseObject) {
        const NSInteger masterMute = [self valueForVolumeKey:@"Mute"
                                                   atChannel:@"Master"
                                                  inResponse:responseObject];

        if (masterMute == kValueNotFound)
        {
            if (failure)
                failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Could not find mute in subscription response"]);
        } else
        {
            if (success)
                success((BOOL) masterMute);
        }
    };

    CNTServiceSubscription *subscription = [CNTServiceSubscription subscriptionWithDelegate:self target:_renderingControlEventURL payload:nil callId:-1];
    [subscription addSuccess:successBlock];
    [subscription addFailure:failure];
    [subscription subscribe];
    return subscription;
}

#pragma mark - Playlist controls

- (id <CNTPlayListControl>)playListControl
{
    return self;
}

- (CNTCapabilityPriorityLevel) playListControlPriority
{
    return CNTCapabilityPriorityLevelNormal;
}

- (void) playNextWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *nextXML = [self commandXMLForCommandName:@"Next"
                                      commandNamespace:kAVTransportNamespace
                                        andWriterBlock:nil];
    NSDictionary *nextPayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Next\"",
            kCNTDataFieldName : nextXML};
    
    CNTServiceCommand *nextCommand = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_avTransportControlURL payload:nextPayload];
    nextCommand.callbackComplete = ^(NSDictionary *responseDic){
        if (success)
            success(nil);
    };
    nextCommand.callbackError = failure;
    [nextCommand send];
}

- (void) playPreviousWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *previousXML = [self commandXMLForCommandName:@"Previous"
                                      commandNamespace:kAVTransportNamespace
                                            andWriterBlock:nil];
    NSDictionary *previousPayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Previous\"",
            kCNTDataFieldName : previousXML};
    
    CNTServiceCommand *previousCommand = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_avTransportControlURL payload:previousPayload];
    previousCommand.callbackComplete = ^(NSDictionary *responseDic){
        if (success)
            success(nil);
    };
    previousCommand.callbackError = failure;
    [previousCommand send];
}

- (void)jumpToTrackWithIndex:(NSInteger)index success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    // our index is zero-based, but in DLNA, track numbers start at 1, so
    // increase by one
    NSString *trackNumberInString = [NSString stringWithFormat:@"%ld", (long)(index + 1)];
    NSString *seekXML = [self commandXMLForCommandName:@"Seek"
                                      commandNamespace:kAVTransportNamespace
                                        andWriterBlock:^(XMLWriter *writer) {
                                            [writer writeElement:@"Unit" withContents:@"TRACK_NR"];
                                            [writer writeElement:@"Target" withContents:trackNumberInString];
                                        }];
    NSDictionary *seekPayload = @{kActionFieldName : @"\"urn:schemas-upnp-org:service:AVTransport:1#Seek\"",
            kCNTDataFieldName : seekXML};
    
    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.serviceCommandDelegate target:_avTransportControlURL payload:seekPayload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

#pragma mark - Private

- (CNTDLNAHTTPServer *)createDLNAHTTPServer {
    return [CNTDLNAHTTPServer new];
}

- (CNTDeviceServiceReachability *)createDeviceServiceReachabilityWithTargetURL:(NSURL *)url {
    return [CNTDeviceServiceReachability reachabilityWithTargetURL:url];
}

@end
