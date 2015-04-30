//
//  CNTNetcastTVService.m
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
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

#import "CNTNetcastTVService_Private.h"
#import "CNTConnectError.h"
#import "CTXMLReader.h"
#import "GCDWebServer.h"
#import "GCDWebServerDataRequest.h"
#import "CNTConnectUtil.h"
#import "CNTDeviceServiceReachability.h"
#import "CNTDiscoveryManager.h"
#import "CNTServiceAsyncCommand.h"
#import "CNTCommonMacros.h"

#import "XMLWriter+CNTConvenienceMethods.h"

#define kSmartShareName @"SmartShare™"

typedef enum {
    LGE_EVENT_REQUEST = 0,
    LGE_COMMAND_REQUEST,
    LGE_AUTH_REQUEST,
    LGE_DATA_GET_REQUEST,
    LGE_STREAMING_REQUEST,
    LGE_QUERY_REQUEST,
    LGE_PAIRING_REQUEST,
    LGE_APPTOAPP_DATA_REQUEST
} LGE_REQUEST_TYPE;

@interface CNTNetcastTVService () <CNTServiceCommandDelegate, UIAlertViewDelegate, CNTDeviceServiceReachabilityDelegate>
{
    NSOperationQueue *_commandQueue;
    BOOL _mouseVisible;

    GCDWebServer *_subscriptionServer;
    NSString *_keyboardString;

    // TODO: pull pairing timer from CNTWebOSTVService
    UIAlertView *_pairingAlert;

    NSMutableDictionary *_subscribed;
    NSURL *_commandURL;

    BOOL _reconnectOnWake;

    CGVector _mouseDistance;
    BOOL _mouseIsMoving;

    CNTDeviceServiceReachability *_serviceReachability;
}

@end

@implementation CNTNetcastTVService

@synthesize dialService = _dialService;
@synthesize dlnaService = _dlnaService;

NSString *lgeUDAPRequestURI[8] = {
        @"/udap/api/event",				//LGE_EVENT_REQUEST
        @"/udap/api/command",			//LGE_COMMAND_REQUEST
        @"/udap/api/auth",              //LGE_AUTH_REQUEST
        @"/udap/api/data",            	//LGE_DATA_GET_REQUEST
        @"/",		                    //LGE_STREAMING_REQUEST
        @"/udap/api/query",			    //LGE_QUERY_REQUEST
        @"/udap/api/pairing",            //LGE_PAIRING_REQUEST
        @"/udap/api/apptoapp/data"      //LGE_APPTOAPP_DATA_REQUEST
};

- (void) commonConfig
{
    _dlnaService = [[CNTDLNAService alloc] initWithServiceConfig:self.serviceConfig];
}

- (instancetype) initWithJSONObject:(NSDictionary *)dict
{
    self = [super initWithJSONObject:dict];

    if (self)
    {
        [self commonConfig];
    }

    return self;
}

- (instancetype) initWithServiceConfig:(CNTServiceConfig *)serviceConfig
{
    self = [super init];

    if (self)
    {
        [self setServiceConfig:serviceConfig];
    }

    return self;
}

- (CNTNetcastTVServiceConfig *)netcastTVServiceConfig {
    return ([self.serviceConfig isKindOfClass:[CNTNetcastTVServiceConfig class]] ?
            (CNTNetcastTVServiceConfig *)self.serviceConfig :
            nil);
}

- (void) setServiceConfig:(CNTServiceConfig *)serviceConfig
{
    const BOOL oldServiceConfigHasCode = (self.netcastTVServiceConfig.pairingCode != nil);
    if ([serviceConfig isKindOfClass:[CNTNetcastTVServiceConfig class]])
    {
        const BOOL newServiceConfigHasCode = (((CNTNetcastTVServiceConfig *)serviceConfig).pairingCode != nil);
        const BOOL wouldLoseCode = oldServiceConfigHasCode && !newServiceConfigHasCode;
        _CNT_assert_state(!wouldLoseCode, @"Replacing important data!");

        [super setServiceConfig:serviceConfig];
    } else
    {
        _CNT_assert_state(!oldServiceConfigHasCode, @"Replacing important data!");

        [super setServiceConfig:[[CNTNetcastTVServiceConfig alloc] initWithServiceConfig:serviceConfig]];
    }
}

- (void)setServiceDescription:(CNTServiceDescription *)serviceDescription
{
    [super setServiceDescription:serviceDescription];

    if (!self.serviceConfig.UUID)
        self.serviceConfig.UUID = serviceDescription.UUID;

    [_dlnaService setServiceDescription:serviceDescription];
}

- (NSURL *)commandURL
{
    if (_commandURL == nil)
    {
        NSString *commandPath = [NSString stringWithFormat:@"http://%@:8080", self.serviceDescription.address];
        _commandURL = [NSURL URLWithString:commandPath];
    }

    return _commandURL;
}

- (void) updateCapabilities
{
    NSArray *capabilities = [NSArray array];

    if ([CNTDiscoveryManager sharedManager].pairingLevel == CNTDeviceServicePairingLevelOn)
    {
        capabilities = [capabilities arrayByAddingObjectsFromArray:kCNTTextInputControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kCNTMouseControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kCNTKeyControlCapabilities];
        capabilities = [capabilities arrayByAddingObject:kCNTPowerControlOff];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kCNTMediaPlayerCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:@[
                kCNTMediaControlPlay,
                kCNTMediaControlPause,
                kCNTMediaControlStop,
                kCNTMediaControlRewind,
                kCNTMediaControlFastForward,
                kCNTMediaControlPlayState,
                kCNTMediaControlPosition,
                kCNTMediaControlDuration,
                kCNTMediaControlSeek,

                kCNTLauncherApp,
                kCNTLauncherAppClose,
                kCNTLauncherAppStore,
                kCNTLauncherAppList,
                kCNTLauncherAppState,
                kCNTLauncherBrowser,
                kCNTLauncherHulu,
                kCNTLauncherNetflix,
                kCNTLauncherNetflixParams,
                kCNTLauncherYouTube,
                kCNTLauncherYouTubeParams,

                kCNTTVControlChannelUp,
                kCNTTVControlChannelDown,
                kCNTTVControlChannelGet,
                kCNTTVControlChannelList,
                kCNTTVControlChannelSubscribe,
                kCNTTVControl3DGet,
                kCNTTVControl3DSet,
                kCNTTVControl3DSubscribe,

                kCNTExternalInputControlPickerLaunch,
                kCNTExternalInputControlPickerClose,

                kCNTVolumeControlVolumeGet,
                kCNTVolumeControlVolumeUpDown,
                kCNTVolumeControlMuteGet,
                kCNTVolumeControlMuteSet
        ]];

        if ([self.modelNumber isEqualToString:@"4.0"])
        {
            capabilities = [capabilities arrayByAddingObjectsFromArray:@[
                    kCNTLauncherAppStoreParams
            ]];
        }
    } else
    {
        // TODO: need to handle some of these controls over DLNA if no pairing
        capabilities = [capabilities arrayByAddingObjectsFromArray:kCNTMediaPlayerCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:@[
                kCNTMediaControlPlay,
                kCNTMediaControlPause,
                kCNTMediaControlStop,
                kCNTMediaControlRewind,
                kCNTMediaControlFastForward,
                kCNTMediaPlayerMetaDataTitle,
                kCNTMediaPlayerMetaDataMimeType,

                kCNTLauncherYouTube,
                kCNTLauncherYouTubeParams
        ]];
    }

    [self setCapabilities:capabilities];
}

+ (NSDictionary *) discoveryParameters
{
    /*
     CNTNetcastTVService and CNTDLNAService have the same ssdp.filter, but
     requiredServices was missing here. That could create differences in device
     discovery with DLNA and (with or without Netcast). e.g., when a device had
     this filter, but not the required services, Netcast would pass it even if
     it is a generic DLNA device. Moreover, that would depend on the order of
     adding services to the CNTDiscoveryManager.
     To avoid the inconsistency, CNTNetcastTVService has the same requiredServices
     as CNTDLNAService.
     */

    return @{
             @"serviceId": kCNTConnectSDKNetcastTVServiceId,
             @"ssdp":@{
                    @"filter":@"urn:schemas-upnp-org:device:MediaRenderer:1",
                    // `requiredServices` from the `CNTDLNAService`, see comment above
                    @"requiredServices": @[
                            @"urn:schemas-upnp-org:service:AVTransport:1",
                            @"urn:schemas-upnp-org:service:RenderingControl:1"
                    ],
                    @"userAgentToken":@"UDAP/2.0"
                }
             };
}

- (void) dealloc
{
    [self.commandQueue cancelAllOperations];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];

}

#pragma mark - Getters & Setters

/// Returns the set delegate property value or self.
- (id<CNTServiceCommandDelegate>)serviceCommandDelegate {
    return _serviceCommandDelegate ?: self;
}

#pragma mark - Connection & Pairing

- (BOOL)isConnectable
{
    return YES;
}

- (void)connect
{
    if (self.connected)
        return;

    if (self.netcastTVServiceConfig.pairingCode)
        [self pairWithData:self.netcastTVServiceConfig.pairingCode];
    else
    {
        if ([CNTDiscoveryManager sharedManager].pairingLevel == CNTDeviceServicePairingLevelOn)
            [self invokePairing];
        else
            [self hConnectSuccess];
    }
}

- (void) hConnectSuccess
{
    _serviceReachability = [CNTDeviceServiceReachability reachabilityWithTargetURL:self.commandURL];
    _serviceReachability.delegate = self;
    [_serviceReachability start];

    self.connected = YES;

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void) didLoseReachability:(CNTDeviceServiceReachability *)reachability
{
    if (self.connected)
        [self disconnect];
    else
        [_serviceReachability stop];
}

- (void) invokePairing
{
    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_PAIRING_REQUEST]];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *payload = @
            "<envelope>"
                "<api type=\"pairing\">"
                    "<name>showKey</name>"
                "</api>"
            "</envelope>";

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        [self showPairingDialog];
        [self.delegate deviceService:self pairingRequiredOfType:self.pairingType withData:self.pairingData];
    };
    command.callbackError = ^(NSError *error)
    {
        [self.delegate deviceService:self didFailConnectWithError:error];
    };
    [command send];
}

- (void) showPairingDialog
{
    NSString *title = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_Title" value:@"Pairing with device" table:@"ConnectSDK"];
    NSString *message = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_Request_Pin" value:@"Please enter the pin code" table:@"ConnectSDK"];
    NSString *ok = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_OK" value:@"OK" table:@"ConnectSDK"];
    NSString *cancel = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_Cancel" value:@"Cancel" table:@"ConnectSDK"];

    _pairingAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:ok, nil];
    _pairingAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [_pairingAlert show];
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
    [alertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumberPad;
}

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
        [self dismissPairingWithSuccess:nil failure:nil];
    else if (buttonIndex == 1)
    {
        NSString *pairingCode = [_pairingAlert textFieldAtIndex:0].text;
        [self pairWithData:pairingCode];
    }
}

- (void) dismissPairingWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_PAIRING_REQUEST]];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *payload = @
            "<envelope>"
                "<api type=\"pairing\">"
                    "<name>byebye</name>"
                    "<port>8080</port>"
                "</api>"
            "</envelope>";

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)disconnect
{
    if (!self.connected)
        return;

    if (!_reconnectOnWake)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    }

    self.connected = NO;
    [self stopSubscriptionServer];

    [self dismissPairingWithSuccess:^(id responseObject)
    {
        [self.commandQueue cancelAllOperations];
    } failure:nil];

    [_serviceReachability stop];

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:nil]; });
}

- (void) startSubscriptionServer
{
    typedef void (^ TextEditedHandler)(NSString *);
    
    TextEditedHandler textEditedHandler = ^(NSString *text) {
        _keyboardString = text;
    };
    
    typedef void (^ SubscriptionHandler)(NSString *, NSDictionary *);
    
    SubscriptionHandler subscriptionHandler = ^(NSString *eventName, NSDictionary *responseXML) {
        CNTServiceSubscription *subscription = [_subscribed objectForKey:eventName];
        
        if (subscription)
        {
            [subscription.successCalls enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
             {
                 ((CNTSuccessBlock) obj)(responseXML);
             }];
        }
    };
    
    _subscriptionServer = [[GCDWebServer alloc] init];

        [_subscriptionServer addDefaultHandlerForMethod:@"POST"
                                       requestClass:[GCDWebServerDataRequest class]
                                       processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                                           GCDWebServerDataRequest *dataRequest = (GCDWebServerDataRequest *)request;

                                           NSError *xmlError;
                                           NSDictionary *responseXML = [CTXMLReader dictionaryForXMLData:dataRequest.data error:&xmlError];

                                           if (!xmlError)
                                           {
                                               NSString *eventName = [[[[responseXML objectForKey:@"envelope"] objectForKey:@"api"] objectForKey:@"name"] objectForKey:@"text"];

                                               if ([eventName isEqualToString:@"TextEdited"])
                                               {
                                                   NSString *text = [[[[responseXML objectForKey:@"envelope"] objectForKey:@"api"] objectForKey:@"value"] objectForKey:@"text"];

                                                   if (text && text.length > 0)
                                                       dispatch_on_main(^{ textEditedHandler(text); });
                                               } else
                                               {
                                                   dispatch_on_main(^{ subscriptionHandler(eventName, responseXML); });
                                               }
                                           }

                                           return [GCDWebServerResponse responseWithStatusCode:200];

                                       }];

    [_subscriptionServer startWithPort:8080 bonjourName:nil];
}

- (void) stopSubscriptionServer
{
    if (_subscriptionServer)
    {
        if ([_subscriptionServer isRunning])
        {
            [_subscriptionServer stop];
        }
        _subscriptionServer = nil;
    }
}

- (void) hAppDidEnterBackground:(NSNotification *)notification
{
    if (self.connected)
    {
        _reconnectOnWake = YES;
        [self disconnect];
    }
}

- (void) hAppDidBecomeActive:(NSNotification *)notification
{
    if (_reconnectOnWake)
    {
        [self connect];
        _reconnectOnWake = NO;
    }
}

#pragma mark - Pairing

- (BOOL) requiresPairing
{
    return [CNTDiscoveryManager sharedManager].pairingLevel == CNTDeviceServicePairingLevelOn;
}

- (CNTDeviceServicePairingType)pairingType
{
    return CNTDeviceServicePairingTypePinCode;
}

- (id)pairingData
{
    return @{
            @"keyLength" : @(6)
    };
}

- (void)pairWithData:(NSString *)pairingCode
{
    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_PAIRING_REQUEST]];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *payload = [NSString stringWithFormat:@
            "<envelope>"
                "<api type=\"pairing\">"
                    "<name>hello</name>"
                    "<value>%@</value>"
                    "<port>%@</port>"
                "</api>"
            "</envelope>", pairingCode, self.commandURL.port];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
    command.callbackComplete = ^(NSDictionary *responseDic){
        self.netcastTVServiceConfig.pairingCode = pairingCode;

        if ([CNTDeviceService shouldDisconnectOnBackground])
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hAppDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hAppDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        }

        [self startSubscriptionServer];

        if (self.delegate && [self.delegate respondsToSelector:@selector(deviceServicePairingSuccess:)])
            dispatch_on_main(^{ [self.delegate deviceServicePairingSuccess:self]; });

        [self hConnectSuccess];
    };
    command.callbackError = ^(NSError *error)
    {
        [self.delegate deviceService:self pairingFailedWithError:error];
    };
    [command send];
}

#pragma mark - ServiceCommandDelegate

- (int) sendCommand:(CNTServiceCommand *)command withPayload:(NSString *)payload toURL:(NSURL *)URL
{
    NSString *xml = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>%@", payload];
    NSData *xmlData = [xml dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];

    NSString *dataLength = [NSString stringWithFormat:@"%i", (unsigned int) [xmlData length]];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    [request setTimeoutInterval:30];
    [request setValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Close" forHTTPHeaderField:@"Connection"];
    [request setValue:@"Apple iOS UDAP/2.0 Connect SDK" forHTTPHeaderField:@"User-Agent"];
    [request setHTTPMethod:command.HTTPMethod];

    if (payload && payload.length > 0)
    {
        [request setValue:dataLength forHTTPHeaderField:@"Content-Length"];
        [request setHTTPBody:xmlData];
    }

    DLog(@"[OUT] : %@ \n %@", [request allHTTPHeaderFields], xml);

    [NSURLConnection sendAsynchronousRequest:request queue:self.commandQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
    {
        DLog(@"[IN] : %@", [((NSHTTPURLResponse *)response) allHeaderFields]);

        if (connectionError || !data)
        {
            if (command.callbackError)
                dispatch_on_main(^{ command.callbackError(connectionError); });
        } else
        {
            if ([data length] == 0)
            {
                id contentLengthValue = [[((NSHTTPURLResponse *) response) allHeaderFields] objectForKey:@"Content-Length"];

                if (contentLengthValue)
                {
                    int contentLength = [contentLengthValue intValue];

                    if (contentLength > 0)
                    {
                        if (command.callbackError)
                            dispatch_on_main(^{ command.callbackError([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeTvError andDetails:@"Expected data from server, but did not receive any."]); });

                        return;
                    }
                }

                if (command.callbackComplete)
                    dispatch_on_main(^{ command.callbackComplete(nil); });
            } else
            {
                NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

                DLog(@"[IN] : %@", dataString);
                
                if (dataString)
                {
                    NSError *commandError = [self parseCommandResponse:response
                                                                  data:dataString];
                    if (commandError)
                    {
                        if (command.callbackError)
                            dispatch_on_main(^{ command.callbackError(commandError); });
                    } else
                    {
                        NSError *xmlError;
                        NSDictionary *responseDic = [CTXMLReader dictionaryForXMLData:data error:&xmlError];

                        if (xmlError || !responseDic)
                        {
                            if (command.callbackComplete)
                                dispatch_on_main(^{ command.callbackComplete(dataString); });
                        } else
                        {
                            if (command.callbackComplete)
                                dispatch_on_main(^{ command.callbackComplete(responseDic); });
                        }
                    }
                } else
                {
                    if (command.callbackComplete)
                        dispatch_on_main(^{ command.callbackComplete(nil); });
                }
            }
        }

    }];

    // TODO: implement callIds
    return 0;
}

#pragma mark - Helper methods

- (NSError *)parseCommandResponse:(NSURLResponse *)response data:(NSString *)responseData
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    NSString *errorMessage;

    switch ([httpResponse statusCode])
    {
        case 400:
            errorMessage = @"The command format is not valid or it has an incorrect value.";
            break;

        case 401:
            errorMessage = @"A command is sent when a Host and a Controller are not paired.";
            break;

        case 404:
            errorMessage = @"The POST path of a command is incorrect.";
            break;

        case 500:
            errorMessage = @"The command execution has failed.";
            break;

        default:
            break;
    }

    NSError *error;
    if (errorMessage)
    {
        error = [CNTConnectError generateErrorWithCode:CNTConnectStatusCodeTvError
                                            andDetails:errorMessage];
    }

    return error;
}

- (NSOperationQueue *)commandQueue
{
    if (_commandQueue == nil)
    {
        _commandQueue = [[NSOperationQueue alloc] init];
    }

    return _commandQueue;
}

+ (CNTChannelInfo *)channelInfoFromXML:(NSDictionary *)info
{
    CNTChannelInfo *channelInfo = [[CNTChannelInfo alloc] init];
    channelInfo.id = [[info objectForKey:@"physicalNum"] objectForKey:@"text"];
    channelInfo.name = [[info objectForKey:@"chname"] objectForKey:@"text"];
    channelInfo.number = [NSString stringWithFormat:@"%@-%@",
                                                           [[info objectForKey:@"major"] objectForKey:@"text"],
                                                           [[info objectForKey:@"minor"] objectForKey:@"text"]];
    channelInfo.majorNumber = [[[info objectForKey:@"displayMajor"] objectForKey:@"text"] intValue];
    channelInfo.minorNumber = [[[info objectForKey:@"displayMinor"] objectForKey:@"text"] intValue];
    channelInfo.rawData = [info copy];

    return channelInfo;
}

+ (CNTAppInfo *)appInfoFromXML:(NSDictionary *)info
{
    CNTAppInfo *appInfo = [[CNTAppInfo alloc] init];
    appInfo.name = [[info objectForKey:@"name"] objectForKey:@"text"];
    appInfo.id = [[info objectForKey:@"auid"] objectForKey:@"text"];
    appInfo.rawData = [info copy];

    appInfo.rawData[@"cpid"][@"text"] = @"";

    return appInfo;
}

- (NSString *) modelNumber
{
    if (self.serviceDescription.modelNumber == nil)
    {
        NSString *xmlString = self.dlnaService.serviceDescription.locationXML;
        NSError *xmlError;
        NSDictionary *xml = [CTXMLReader dictionaryForXMLString:xmlString error:&xmlError];

        if (!xmlError)
        {
            NSString *model = [[[[xml objectForKey:@"root"] objectForKey:@"device"] objectForKey:@"modelNumber"] objectForKey:@"text"];

            if (model)
                self.serviceDescription.modelNumber = [[[model stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""] stringByReplacingOccurrencesOfString:@"\t" withString:@""];
        }
    }

    return self.serviceDescription.modelNumber;
}

#pragma mark - Launcher

- (id <CNTLauncher>)launcher
{
    return self;
}

- (CNTCapabilityPriorityLevel) launcherPriority
{
    return CNTCapabilityPriorityLevelHigh;
}

- (void)getAppListWithSuccess:(CNTAppListSuccessBlock)success failure:(CNTFailureBlock)failure
{
    // This is a very inefficient solution for getting a full app list. This particular solution is
    // required to support 2012 Netcast TVs, which require an app count for getting a list of apps.
    // 2012 Netcast TVs also don't support getting an "all apps" list or list count.

    static int APP_TYPE_PREMIUM = 2;
    static int APP_TYPE_MY_APPS = 3;

    __block int premiumAppsCount;
    __block int myAppsCount;

    __block NSArray *premiumApps;
    __block NSArray *myApps;

    [self getNumberOfAppsForType:APP_TYPE_PREMIUM success:^(int numberOfPremiumApps)
    {
        premiumAppsCount = numberOfPremiumApps;

        [self getNumberOfAppsForType:APP_TYPE_MY_APPS success:^(int numberOfMyApps)
        {
            myAppsCount = numberOfMyApps;

            [self getAppListForType:APP_TYPE_PREMIUM numberOfApps:premiumAppsCount success:^(NSArray *premiumAppsList)
            {
                premiumApps = premiumAppsList;

                [self getAppListForType:APP_TYPE_MY_APPS numberOfApps:myAppsCount success:^(NSArray *myAppsList)
                {
                    myApps = myAppsList;

                    NSMutableDictionary *allApps = [[NSMutableDictionary alloc] init];

                    [premiumApps enumerateObjectsUsingBlock:^(CNTAppInfo *appInfo, NSUInteger idx, BOOL *stop)
                    {
                        if (appInfo)
                            [allApps setObject:appInfo forKey:appInfo.id];
                    }];

                    [myApps enumerateObjectsUsingBlock:^(CNTAppInfo *appInfo, NSUInteger idx, BOOL *stop)
                    {
                        if (appInfo)
                            [allApps setObject:appInfo forKey:appInfo.id];
                    }];

                    if (success)
                        success([allApps allValues]);
                } failure:failure];
            } failure:failure];
        } failure:failure];
    } failure:failure];
}

- (void) getNumberOfAppsForType:(int)type success:(void (^)(int numberOfApps))success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [NSString stringWithFormat:@"%@%@%@",
            self.commandURL.absoluteString,
            lgeUDAPRequestURI[LGE_DATA_GET_REQUEST],
            [NSString stringWithFormat:@"?target=appnum_get&type=%d", type]
            ];

    NSURL *targetURL = [NSURL URLWithString:targetPath];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        NSDictionary *rawResponse = [[[responseDic objectForKey:@"envelope"] objectForKey:@"dataList"] objectForKey:@"data"];
        NSNumber *numberOfApps = [[rawResponse objectForKey:@"number"] objectForKey:@"text"];

        int numberOfAppsInt = numberOfApps.intValue;

        if (numberOfAppsInt == 0)
        {
            if (failure)
                failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeTvError andDetails:@""]);
        } else
        {
            if (success)
                success(numberOfAppsInt);
        }
    };
    command.callbackError = failure;
    [command send];
}

- (void) getAppListForType:(int)type numberOfApps:(int)numberOfApps success:(CNTAppListSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [NSString stringWithFormat:@"%@%@%@",
            self.commandURL.absoluteString,
            lgeUDAPRequestURI[LGE_DATA_GET_REQUEST],
            [NSString stringWithFormat:@"?target=applist_get&type=%d&index=1&number=%d", type, numberOfApps]
    ];

    NSURL *targetURL = [NSURL URLWithString:targetPath];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        NSArray *rawApps = [[[responseDic objectForKey:@"envelope"] objectForKey:@"dataList"] objectForKey:@"data"];
        NSMutableArray *appList = [[NSMutableArray alloc] init];

        [rawApps enumerateObjectsUsingBlock:^(NSDictionary *appInfo, NSUInteger idx, BOOL *stop)
        {
            [appList addObject:[CNTNetcastTVService appInfoFromXML:appInfo]];
        }];

        if (success)
            success([NSArray arrayWithArray:appList]);
    };
    command.callbackError = failure;
    [command send];
}

- (void)launchApp:(NSString *)appId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self getAppInfoForId:appId success:^(CNTAppInfo *appInfo)
    {
        [self launchAppWithInfo:appInfo success:success failure:failure];
    } failure:failure];
}

- (void)launchAppWithInfo:(CNTAppInfo *)appInfo success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_COMMAND_REQUEST]];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *payload = [NSString stringWithFormat:@
                                                           "<envelope>"
                                                               "<api type=\"command\">"
                                                                   "<name>AppExecute</name>"
                                                                   "<auid>%@</auid>"
                                                                   "<appname>%@</appname>"
                                                                   "<contentId>%@</contentId>"
                                                               "</api>"
                                                           "</envelope>",
                                                   appInfo.id, appInfo.name, [[appInfo.rawData objectForKey:@"cpid"] objectForKey:@"text"]];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:appInfo.id];
        launchSession.name = appInfo.name;
        launchSession.sessionType = CNTLaunchSessionTypeApp;
        launchSession.service = self;
        launchSession.rawData = [responseObject copy];

        if (success)
            success(launchSession);
    };
    command.callbackError = failure;
    [command send];
}

- (void)getAppInfoForId:(NSString *)appId success:(CNTAppInfoSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self getAppListWithSuccess:^(NSArray *appList)
    {
        __block CNTAppInfo *appInfo;

        [appList enumerateObjectsUsingBlock:^(CNTAppInfo *app, NSUInteger idx, BOOL *stop)
        {
            if ([app.name.lowercaseString isEqualToString:appId.lowercaseString])
            {
                appInfo = app;
                *stop = YES;
            }
        }];

        if (appInfo && success)
            success(appInfo);

        if (appInfo == nil && failure)
            failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Could not find app with specified id."]);
    } failure:failure];
}

- (void)launchApplication:(NSString *)appId withParams:(NSDictionary *)params success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)launchAppWithInfo:(CNTAppInfo *)appInfo params:(NSDictionary *)params success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void) launchAppStore:(NSString *)appId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:@"roap"];
    targetPath = [targetPath stringByAppendingPathComponent:@"api"];
    targetPath = [targetPath stringByAppendingPathComponent:@"command"];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *payload = [NSString stringWithFormat:@
                                                           "<envelope>"
                                                           "<api type=\"command\">"
                                                           "<name>SearchCMDPlaySDPContent</name>"
                                                           "<content_type>4</content_type>"
                                                           "<conts_exec_type />"
                                                           "<conts_plex_type_flag />"
                                                           "<conts_search_id />"
                                                           "<conts_age>12</conts_age>"
                                                           "<exec_id />"
                                                           "<item_id>%@</item_id>"
                                                           "<app_type>S</app_type>"
                                                           "</api>"
                                                           "</envelope>", [CNTConnectUtil urlEncode:appId]];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
    command.callbackComplete = ^(id responseObject)
    {
        CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:@""];
        launchSession.name = @"LG Smart World"; // TODO: this will not work in Korea, use "LG 스마트 월드" instead
        launchSession.sessionType = CNTLaunchSessionTypeApp;
        launchSession.service = self;

        if (success)
            success(launchSession);
    };
    command.callbackError = failure;
    [command send];
}

- (void)launchBrowser:(NSURL *)target success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self launchApp:@"Internet" success:success failure:failure];
}

- (void)launchHulu:(NSString *)contentId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self getAppInfoForId:@"Hulu Plus" success:^(CNTAppInfo *appInfo)
    {
        [[appInfo.rawData objectForKey:@"cpid"] setObject:contentId forKey:@"text"];

        if (success)
            [self launchAppWithInfo:appInfo success:success failure:failure];
    } failure:failure];
}

- (void)launchNetflix:(NSString *)contentId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (![[self modelNumber] isEqualToString:@"4.0"])
    {
        [self launchApp:@"Netflix" success:success failure:failure];
        return;
    }

    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_COMMAND_REQUEST]];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *contentPath = [NSString stringWithFormat:@"http://api.netflix.com/catalog/titles/movies/%@&source_type=4&trackId=6054700&trackUrl=https://api.netflix.com/API_APP_ID_6261?#Search?", contentId];
    NSString *payload = [NSString stringWithFormat:@
                                                           "<envelope>"
                                                               "<api type=\"command\">"
                                                                   "<name>SearchCMDPlaySDPContent</name>"
                                                                   "<content_type>1</content_type>"
                                                                   "<conts_exec_type>20</conts_exec_type>"
                                                                   "<conts_plex_type_flag>N</conts_plex_type_flag>"
                                                                   "<conts_search_id>2023237</conts_search_id>"
                                                                   "<conts_age>18</conts_age>"
                                                                   "<exec_id>netflix</exec_id>"
                                                                   "<item_id>-Q m=%@</item_id>"
                                                                   "<app_type></app_type>"
                                                               "</api>"
                                                           "</envelope>", [CNTConnectUtil urlEncode:contentPath]];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)launchYouTube:(NSString *)contentId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.launcher launchYouTube:contentId startTime:0.0 success:success failure:failure];
}

- (void) launchYouTube:(NSString *)contentId startTime:(float)startTime success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dialService)
    {
        [self.dialService.launcher launchYouTube:contentId startTime:startTime success:success failure:failure];
        return;
    }

    if (startTime <= 0.0)
    {
        [self getAppInfoForId:@"YouTube" success:^(CNTAppInfo *appInfo)
        {
            [[appInfo.rawData objectForKey:@"cpid"] setObject:contentId forKey:@"text"];

            if (success)
                [self launchAppWithInfo:appInfo success:success failure:failure];
        } failure:failure];
    } else
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:@"Cannot reach DIAL service for launching with provided start time"]);
    }
}

- (void)closeApplicationWithName:(NSString *)appId success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self getAppInfoForId:appId success:^(CNTAppInfo *info)
    {
        CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:info.id];
        launchSession.name = info.name;
        launchSession.sessionType = CNTLaunchSessionTypeApp;
        launchSession.service = self;

        [self closeApp:launchSession success:success failure:failure];
    } failure:failure];
}

- (void)closeApp:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (![launchSession.name isEqualToString:kSmartShareName])
    {
        if (launchSession.appId == nil || launchSession.appId.length == 0)
        {
            [self closeApplicationWithName:launchSession.name success:success failure:failure];
            return;
        }
    }

    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_COMMAND_REQUEST]];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *appId = (launchSession.appId) ? launchSession.appId : @"";
    NSString *appName = (launchSession.name) ? launchSession.name : @"";

    NSString *payload = [NSString stringWithFormat:@
                                                           "<envelope>"
                                                               "<api type=\"command\">"
                                                                   "<name>AppTerminate</name>"
                                                                   "<auid>%@</auid>"
                                                                   "<appname>%@</appname>"
                                                               "</api>"
                                                           "</envelope>", appId, appName];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
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

- (void)getAppState:(CNTLaunchSession *)launchSession success:(CNTAppStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [NSString stringWithFormat:@"%@%@%@",
            self.commandURL.absoluteString,
            lgeUDAPRequestURI[LGE_APPTOAPP_DATA_REQUEST],
            [NSString stringWithFormat:@"/%@/status", launchSession.appId]
    ];

    NSURL *targetURL = [NSURL URLWithString:targetPath];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:nil];
    command.callbackComplete = ^(NSString *response)
    {
        // TODO: need to test this
        if (success)
        {
            if ([response isEqualToString:@"NONE"]) success(NO, NO);
            else if ([response isEqualToString:@"LOAD"]) success(NO, YES);
            else if ([response isEqualToString:@"RUN_NF"]) success(YES, NO);
            else if ([response isEqualToString:@"TERM"]) success(NO, YES);
            else success(NO, NO);
        }
    };
    command.callbackError = failure;
    [command send];
}

- (CNTServiceSubscription *)subscribeAppState:(CNTLaunchSession *)launchSession success:(CNTAppStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (CNTDLNAService *)dlnaService
{
    if (_dlnaService == nil)
    {
        CNTDiscoveryManager *discoveryManager = [CNTDiscoveryManager sharedManager];
        CNTConnectableDevice *device = [discoveryManager.allDevices objectForKey:self.serviceDescription.address];

        if (device)
        {
            __block CNTDLNAService *foundService;

            [device.services enumerateObjectsUsingBlock:^(CNTDeviceService *service, NSUInteger idx, BOOL *stop)
            {
                if ([service isKindOfClass:[CNTDLNAService class]])
                {
                    foundService = (CNTDLNAService *)service;
                    *stop = YES;
                }
            }];

            _dlnaService = foundService;
        }
    }

    return _dlnaService;
}

- (CNTDIALService *)dialService
{
    if (_dialService == nil)
    {
        CNTDiscoveryManager *discoveryManager = [CNTDiscoveryManager sharedManager];
        CNTConnectableDevice *device = [discoveryManager.allDevices objectForKey:self.serviceDescription.address];

        if (device)
        {
            __block CNTDIALService *foundService;

            [device.services enumerateObjectsUsingBlock:^(CNTDeviceService *service, NSUInteger idx, BOOL *stop)
            {
                if ([service isKindOfClass:[CNTDIALService class]])
                {
                    foundService = (CNTDIALService *)service;
                    *stop = YES;
                }
            }];

            _dialService = foundService;
        }
    }

    return _dialService;
}

#pragma mark - Media Player

- (id <CNTMediaPlayer>)mediaPlayer
{
    return self;
}

- (CNTCapabilityPriorityLevel)mediaPlayerPriority
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

-(void) displayImageWithMediaInfo:(CNTMediaInfo *)mediaInfo success:(CNTMediaPlayerSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dlnaService)
    {
        [self.dlnaService.mediaPlayer displayImageWithMediaInfo:mediaInfo success:^(CNTMediaLaunchObject *launchObject)
         {
             
             launchObject.session.appId = kSmartShareName;
             launchObject.session.name = kSmartShareName;
             
             if (success)
                 success(launchObject);
         } failure:failure];
        return;
    }
    
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);

}

- (void) playMedia:(NSURL *)videoURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(CNTMediaPlayerDisplaySuccessBlock)success failure:(CNTFailureBlock)failure
{
    CNTMediaInfo *mediaInfo = [[CNTMediaInfo alloc] initWithURL:videoURL mimeType:mimeType];
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

-(void) playMediaWithMediaInfo:(CNTMediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(CNTMediaPlayerSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dlnaService)
    {
        [self.dlnaService.mediaPlayer playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop success:^(CNTMediaLaunchObject *launchObject)
         {
             launchObject.session.appId = kSmartShareName;
             launchObject.session.name = kSmartShareName;
             
             if (success)
                 success(launchObject);
         } failure:failure];
        return;
    }
    
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)closeMedia:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dlnaService)
    {
        [self.dlnaService closeMedia:launchSession success:success failure:failure];
        return;
    }
    
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

#pragma mark - Media Control

- (id <CNTMediaControl>)mediaControl
{
    if ([CNTDiscoveryManager sharedManager].pairingLevel == CNTDeviceServicePairingLevelOff)
        return self.dlnaService;
    else
        return self;
}

- (CNTCapabilityPriorityLevel)mediaControlPriority
{
    return CNTCapabilityPriorityLevelNormal;
}

- (void)playWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodePlay success:success failure:failure];
}

- (void)pauseWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodePause success:success failure:failure];
}

- (void)stopWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodeStop success:success failure:failure];
}

- (void)rewindWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodeRewind success:success failure:failure];
}

- (void)fastForwardWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodeFastForward success:success failure:failure];
}

- (void)seek:(NSTimeInterval)position success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dlnaService)
    {
        [self.dlnaService seek:position success:success failure:failure];
        return;
    }

    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)getPlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dlnaService)
    {
        [self.dlnaService getPlayStateWithSuccess:success failure:failure];
        return;
    }

    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void) getDurationWithSuccess:(CNTMediaDurationSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dlnaService)
    {
        [self.dlnaService getDurationWithSuccess:success failure:failure];
        return;
    }

    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)getPositionWithSuccess:(CNTMediaPositionSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dlnaService)
    {
        [self.dlnaService getPositionWithSuccess:success failure:failure];
        return;
    }

    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (CNTServiceSubscription *)subscribePlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dlnaService) {
        return [self.dlnaService subscribePlayStateWithSuccess:success failure:failure];
    } else if (failure) {
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
    }

    return nil;
}

- (void)getMediaMetaDataWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dlnaService)
    {
        [self.dlnaService getMediaMetaDataWithSuccess:success failure:failure];
        return;
    }
    
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
    
}

- (CNTServiceSubscription *)subscribeMediaInfoWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dlnaService)
    {
        CNTServiceSubscription *subscription = [self.dlnaService subscribeMediaInfoWithSuccess:success failure:failure];
        return subscription;
    }
    
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
    
    return nil;
}

#pragma mark - TV

- (id <CNTTVControl>)tvControl
{
    return self;
}

- (CNTCapabilityPriorityLevel)tvControlPriority
{
    return CNTCapabilityPriorityLevelHigh;
}

- (void)getCurrentChannelWithSuccess:(CNTCurrentChannelSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [NSString stringWithFormat:@"%@%@%@",
            self.commandURL.absoluteString,
            lgeUDAPRequestURI[LGE_DATA_GET_REQUEST],
            @"?target=cur_channel"
    ];

    NSURL *targetURL = [NSURL URLWithString:targetPath];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        NSDictionary *channelInfo = [[[responseDic objectForKey:@"envelope"] objectForKey:@"dataList"] objectForKey:@"data"];
        
        if (success)
            success([CNTNetcastTVService channelInfoFromXML:channelInfo]);
    };
    command.callbackError = failure;
    [command send];
}

- (CNTServiceSubscription *)subscribeCurrentChannelWithSuccess:(CNTCurrentChannelSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self getCurrentChannelWithSuccess:success failure:failure];

    CNTServiceSubscription *subscription = [self addSubscribe:@"ChannelChanged" success:^(NSDictionary *responseObject)
    {
        NSDictionary *channelInfo = [[responseObject objectForKey:@"envelope"] objectForKey:@"api"];
        
        if (success)
            success([CNTNetcastTVService channelInfoFromXML:channelInfo]);
    } failure:failure];

    return subscription;
}

- (void)getChannelListWithSuccess:(CNTChannelListSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [NSString stringWithFormat:@"%@%@%@",
            self.commandURL.absoluteString,
            lgeUDAPRequestURI[LGE_DATA_GET_REQUEST],
            @"?target=channel_list"
    ];

    NSURL *targetURL = [NSURL URLWithString:targetPath];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        id rawChannelObject = [[[responseDic objectForKey:@"envelope"] objectForKey:@"dataList"] objectForKey:@"data"];
        NSArray *rawChannels;

        if ([rawChannelObject isKindOfClass:[NSArray class]])
            rawChannels = (NSArray *)rawChannelObject;
        else
        {
            if (success)
                success([NSArray array]);
        }

        NSMutableDictionary *channelList = [[NSMutableDictionary alloc] init];

        [rawChannels enumerateObjectsUsingBlock:^(NSDictionary *channelDictionary, NSUInteger idx, BOOL *stop)
        {
            CNTChannelInfo *channelInfo = [CNTNetcastTVService channelInfoFromXML:channelDictionary];

            if (channelInfo)
                [channelList setValue:channelInfo forKey:channelInfo.number];
        }];
        
        if (success)
            success([channelList allValues]);
    };
    command.callbackError = failure;
    [command send];
}

- (void)channelUpWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodeChannelUp success:success failure:failure];
}

- (void)channelDownWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodeChannelDown success:success failure:failure];
}

- (void)setChannel:(CNTChannelInfo *)channelInfo success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *major = [[channelInfo.rawData objectForKey:@"major"] objectForKey:@"text"];
    NSString *minor = [[channelInfo.rawData objectForKey:@"minor"] objectForKey:@"text"];
    NSString *sourceIndex = [[channelInfo.rawData objectForKey:@"sourceIndex"] objectForKey:@"text"];
    NSString *physicalNum = channelInfo.id;

    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_COMMAND_REQUEST]];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *payload = [NSString stringWithFormat:@
                                                           "<envelope>"
                                                               "<api type=\"command\">"
                                                                   "<name>HandleChannelChange</name>"
                                                                   "<major>%@</major>"
                                                                   "<minor>%@</minor>"
                                                                   "<sourceIndex>%@</sourceIndex>"
                                                                   "<physicalNum>%@</physicalNum>"
                                                               "</api>"
                                                           "</envelope>", major, minor, sourceIndex, physicalNum];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getProgramInfoWithSuccess:(CNTProgramInfoSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (CNTServiceSubscription *)subscribeProgramInfoWithSuccess:(CNTProgramInfoSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (void)getProgramListWithSuccess:(CNTProgramListSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (CNTServiceSubscription *)subscribeProgramListWithSuccess:(CNTProgramListSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (void)get3DEnabledWithSuccess:(CNTTV3DEnabledSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [NSString stringWithFormat:@"%@%@%@",
            self.commandURL.absoluteString,
            lgeUDAPRequestURI[LGE_DATA_GET_REQUEST],
            @"?target=is_3d"
    ];

    NSURL *targetURL = [NSURL URLWithString:targetPath];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self target:targetURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        BOOL status = [[[[[[responseObject objectForKey:@"envelope"] objectForKey:@"dataList"] objectForKey:@"data"] objectForKey:@"is3D"] objectForKey:@"text"] isEqualToString:@"true"];

        if (success)
            success(status);
    };
    command.callbackError = failure;
    [command send];
}

- (void)set3DEnabled:(BOOL)enabled success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self get3DEnabledWithSuccess:^(BOOL tv3DEnabled)
    {
        if (tv3DEnabled == enabled)
        {
            if (success)
                success(nil);
        } else
        {
            [self sendKeyCode:CNTNetcastTVKeyCode3DVideo success:success failure:failure];
        }
    } failure:failure];
}

- (CNTServiceSubscription *)subscribe3DEnabledWithSuccess:(CNTTV3DEnabledSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self get3DEnabledWithSuccess:success failure:failure];

    CNTServiceSubscription *subscription = [self addSubscribe:@"3DMode" success:^(NSDictionary *responseObject)
    {
        BOOL status = [[[[[responseObject objectForKey:@"envelope"] objectForKey:@"api"] objectForKey:@"value"] objectForKey:@"text"] isEqualToString:@"true"];

        if (success)
            success(status);
    } failure:failure];

    return subscription;
}

#pragma mark - Volume

- (id <CNTVolumeControl>)volumeControl
{
    return self;
}

- (CNTCapabilityPriorityLevel)volumeControlPriority
{
    return CNTCapabilityPriorityLevelHigh;
}

- (void)getVolumeWithSuccess:(CNTVolumeSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [NSString stringWithFormat:@"%@%@%@",
            self.commandURL.absoluteString,
            lgeUDAPRequestURI[LGE_DATA_GET_REQUEST],
            @"?target=volume_info"
    ];

    NSURL *targetURL = [NSURL URLWithString:targetPath];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        NSDictionary *volumeInfo = [[[responseDic objectForKey:@"envelope"] objectForKey:@"dataList"] objectForKey:@"data"];
        int volume = [[[volumeInfo objectForKey:@"level"] objectForKey:@"text"] intValue];

        if (success)
            success(volume / 100.0f);
    };
    command.callbackError = failure;
    [command send];
}

- (void)getMuteWithSuccess:(CNTMuteSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [NSString stringWithFormat:@"%@%@%@",
            self.commandURL.absoluteString,
            lgeUDAPRequestURI[LGE_DATA_GET_REQUEST],
            @"?target=volume_info"
    ];

    NSURL *targetURL = [NSURL URLWithString:targetPath];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        NSDictionary *volumeInfo = [[[responseDic objectForKey:@"envelope"] objectForKey:@"dataList"] objectForKey:@"data"];
        BOOL mute = [[[volumeInfo objectForKey:@"mute"] objectForKey:@"text"] boolValue];

        if (success)
            success(mute);
    };
    command.callbackError = failure;
    [command send];
}

- (void)setVolume:(float)volume success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dlnaService)
    {
        [self.dlnaService setVolume:volume success:success failure:failure];
        return;
    }
    
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)setMute:(BOOL)mute success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self getMuteWithSuccess:^(BOOL currentMute)
    {
        if (currentMute == mute)
        {
            if (success)
                success(nil);
        } else
            [self sendKeyCode:CNTNetcastTVKeyCodeMute success:success failure:failure];
    } failure:failure];
}

- (void)volumeUpWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodeVolumeUp success:success failure:failure];
}

- (void)volumeDownWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodeVolumeDown success:success failure:failure];
}

- (CNTServiceSubscription *)subscribeVolumeWithSuccess:(CNTVolumeSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dlnaService) {
        return [self.dlnaService subscribeVolumeWithSuccess:success failure:failure];
    } else if (failure) {
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
    }
    
    return nil;
}

- (CNTServiceSubscription *)subscribeMuteWithSuccess:(CNTMuteSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (self.dlnaService) {
        return [self.dlnaService subscribeMuteWithSuccess:success failure:failure];
    } else if (failure) {
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
    }
    
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
    [self sendKeyCode:CNTNetcastTVKeyCodeUp success:success failure:failure];
}

- (void)downWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodeDown success:success failure:failure];
}

- (void)leftWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodeLeft success:success failure:failure];
}

- (void)rightWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodeRight success:success failure:failure];
}

- (void)okWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodeOK success:success failure:failure];
}

- (void)backWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodeBack success:success failure:failure];
}

- (void)homeWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodeHome success:success failure:failure];
}

- (void)sendKeyCode:(CNTNetcastTVKeyCode)keyCode success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self hideMouseWithSuccess:^(id responseObject)
    {
        NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_COMMAND_REQUEST]];
        NSURL *targetURL = [NSURL URLWithString:targetPath];

        NSString *payload = [NSString stringWithFormat:@
                                                               "<envelope>"
                                                               "<api type=\"command\">"
                                                               "<name>HandleKeyInput</name>"
                                                               "<value>%d</value>"
                                                               "</api>"
                                                               "</envelope>", (unsigned int) keyCode];

        CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
        command.callbackComplete = success;
        command.callbackError = failure;
        [command send];
    } failure:failure];
}

#pragma mark - Mouse

- (id <CNTMouseControl>)mouseControl
{
    return self;
}

- (CNTCapabilityPriorityLevel)mouseControlPriority
{
    return CNTCapabilityPriorityLevelHigh;
}

- (void) connectMouseWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    _mouseDistance = CGVectorMake(0, 0);
    _mouseIsMoving = NO;

    [self showMouseWithSuccess:success failure:failure];
}

- (void)disconnectMouse
{
    _mouseDistance = CGVectorMake(0, 0);
    _mouseIsMoving = NO;

    [self hideMouseWithSuccess:nil failure:nil];
}

- (void) showMouseWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (_mouseVisible)
    {
        if (success)
            success(nil);

        return;
    }

    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_EVENT_REQUEST]];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *payload = [NSString stringWithFormat:@
            "<envelope>"
                "<api type=\"event\">"
                    "<name>CursorVisible</name>"
                    "<value>true</value>"
                    "<mode>auto</mode>"
                "</api>"
            "</envelope>"];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
    command.callbackComplete = ^(id responseObject){
        _mouseVisible = YES;
        
        if (success)
            success(nil);
    };
    command.callbackError = failure;
    [command send];
}

- (void) hideMouseWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (!_mouseVisible)
    {
        if (success)
            success(nil);

        return;
    }

    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_EVENT_REQUEST]];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *payload = [NSString stringWithFormat:@
            "<envelope>"
                "<api type=\"event\">"
                    "<name>CursorVisible</name>"
                    "<value>false</value>"
                    "<mode>auto</mode>"
                "</api>"
            "</envelope>"];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
    command.callbackComplete = ^(id responseObject){
        _mouseVisible = NO;

        if (success)
            success(nil);
    };
    command.callbackError = failure;
    [command send];
}

- (void) move:(CGVector)distance success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    _mouseDistance = CGVectorMake(
        _mouseDistance.dx + distance.dx,
        _mouseDistance.dy + distance.dy
    );

    if (!_mouseIsMoving)
    {
        _mouseIsMoving = YES;

        [self moveMouseWithSuccess:success failure:failure];
    }
}

- (void) moveMouseWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_COMMAND_REQUEST]];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *payload = [NSString stringWithFormat:@
                                                           "<envelope>"
                                                               "<api type=\"command\">"
                                                                   "<name>HandleTouchMove</name>"
                                                                   "<x>%i</x>"
                                                                   "<y>%i</y>"
                                                               "</api>"
                                                           "</envelope>", (int) round(_mouseDistance.dx), (int) round(_mouseDistance.dy)];

    _mouseDistance = CGVectorMake(0, 0);

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
    command.callbackComplete = ^(id responseObject)
    {
        if (_mouseDistance.dx != 0 || _mouseDistance.dy != 0)
            [self moveMouseWithSuccess:nil failure:nil];
        else
            _mouseIsMoving = NO;

        if (success)
            success(responseObject);
    };
    command.callbackError = ^(NSError *error)
    {
        _mouseIsMoving = NO;

        if (failure)
            failure(error);
    };
    [command send];
}

- (void) scroll:(CGVector)distance success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_COMMAND_REQUEST]];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *direction = (distance.dy > 0) ? @"down" : @"up";

    NSString *payload = [NSString stringWithFormat:@
                                                           "<envelope>"
                                                               "<api type=\"command\">"
                                                                   "<name>HandleTouchWheel</name>"
                                                                   "<value>%@</value>"
                                                               "</api>"
                                                           "</envelope>", direction];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)clickWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_COMMAND_REQUEST]];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *payload = [NSString stringWithFormat:@
            "<envelope>"
                "<api type=\"command\">"
                    "<name>HandleTouchClick</name>"
                "</api>"
            "</envelope>"];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

#pragma mark - Power Control

- (id <CNTPowerControl>)powerControl
{
    return self;
}

- (CNTCapabilityPriorityLevel)powerControlPriority
{
    return CNTCapabilityPriorityLevelHigh;
}

- (void)powerOffWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self sendKeyCode:CNTNetcastTVKeyCodePower success:success failure:failure];
}

- (void) powerOnWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

#pragma mark - External Input Control

- (id <CNTExternalInputControl>)externalInputControl
{
    return self;
}

- (CNTCapabilityPriorityLevel)externalInputControlPriority
{
    return CNTCapabilityPriorityLevelHigh;
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wformat"
- (void)launchInputPickerWithSuccess:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *appId = @"Input List";

    NSString *targetPath = [NSString stringWithFormat:@"%@%@/%@",
                                                      self.commandURL.absoluteString,
                                                      lgeUDAPRequestURI[LGE_APPTOAPP_DATA_REQUEST],
                                                      [CNTConnectUtil urlEncode:appId]
    ];

    NSURL *targetURL = [NSURL URLWithString:targetPath];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self target:targetURL payload:nil];
    command.HTTPMethod = @"GET";
    command.callbackComplete = ^(NSString *response)
    {
        if (response)
        {
            int auidRawValue = [response intValue];
            NSString *auidString = [[NSString alloc] initWithFormat:@"%lX", auidRawValue];
            

            while (auidString.length < 16)
            {
                auidString = [NSString stringWithFormat:@"0%@", auidString];
            }

            CNTAppInfo *appInfo = [CNTAppInfo appInfoForId:auidString];
            appInfo.name = appId;

            [self launchAppWithInfo:appInfo success:success failure:failure];
        } else
        {
            if (failure)
                failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeError andDetails:@"Could not find app with specified id."]);
        }
    };
    command.callbackError = failure;
    [command send];
}
#pragma GCC diagnostic pop

- (void)closeInputPicker:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    [self.keyControl sendKeyCode:CNTNetcastTVKeyCodeExit success:success failure:failure];
}

- (void)getExternalInputListWithSuccess:(CNTExternalInputListSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)setExternalInput:(CNTExternalInputInfo *)externalInputInfo success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeNotSupported andDetails:nil]);
}

#pragma mark - Text Input Control

- (id <CNTTextInputControl>) textInputControl
{
    return self;
}

- (CNTCapabilityPriorityLevel) textInputControlPriority
{
    return CNTCapabilityPriorityLevelHigh;
}

- (void) sendText:(NSString *)input success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (_keyboardString && _keyboardString.length > 0)
        _keyboardString = [_keyboardString stringByAppendingString:input];
    else
        _keyboardString = input;

    [self sendText:_keyboardString state:@"Editing" success:success failure:failure];
}

- (void)sendEnterWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (_keyboardString && _keyboardString.length > 0)
    {
        [self sendText:_keyboardString state:@"EditEnd" success:nil failure:nil];

        [self sendKeyCode:CNTNetcastTVKeyCodeRed success:^(id responseObject)
        {
            _keyboardString = @"";

            if (success)
                success(nil);
        } failure:failure];
    } else
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeArgumentError andDetails:@"You have not inputted any text to send."]);
    }
}

- (void)sendDeleteWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (_keyboardString && _keyboardString.length > 0)
    {
        _keyboardString = [_keyboardString substringToIndex:_keyboardString.length - 1];
        [self sendText:_keyboardString state:@"Editing" success:success failure:failure];
    } else
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:CNTConnectStatusCodeArgumentError andDetails:@"There are no characters to delete."]);
    }
}

- (void) sendText:(NSString *)text state:(NSString *)state success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    NSString *targetPath = [self.commandURL.absoluteString stringByAppendingPathComponent:lgeUDAPRequestURI[LGE_EVENT_REQUEST]];
    NSURL *targetURL = [NSURL URLWithString:targetPath];

    NSString *payload = ({
        XMLWriter *writer = [XMLWriter new];

        [writer writeElement:@"envelope" withContentsBlock:^(XMLWriter *writer) {
            [writer writeElement:@"api" withContentsBlock:^(XMLWriter *writer) {
                [writer writeAttribute:@"type" value:@"event"];

                [writer writeElement:@"name" withContents:@"TextEdited"];
                [writer writeElement:@"state" withContents:state];
                [writer writeElement:@"value" withContents:text];
            }];
        }];

        [writer toString];
    });

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self.serviceCommandDelegate target:targetURL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (CNTServiceSubscription *) subscribeTextInputStatusWithSuccess:(CNTTextInputStatusInfoSuccessBlock)success failure:(CNTFailureBlock)failure
{
    __weak CNTNetcastTVService *weakSelf = self;
    
    CNTServiceSubscription *serviceSubscription = [self addSubscribe:@"KeyboardVisible" success:^(NSDictionary *responseObject)
    {
        NSString *isVisibleValue = [[[[responseObject objectForKey:@"envelope"] objectForKey:@"api"] objectForKey:@"value"] objectForKey:@"text"];

        CNTTextInputStatusInfo *keyboardInfo = [[CNTTextInputStatusInfo alloc] init];
        keyboardInfo.isVisible = [isVisibleValue isEqualToString:@"true"];
        keyboardInfo.rawData = [responseObject copy];

        [weakSelf sendText:@"" state:@"EditStart" success:nil failure:nil];

        if (success)
            success(keyboardInfo);
    } failure:failure];

    return serviceSubscription;
}

- (int)sendSubscription:(CNTServiceSubscription *)subscription type:(CNTServiceSubscriptionType)type payload:(id)payload toURL:(NSURL *)URL withId:(int)callId
{
    if (type == CNTServiceSubscriptionTypeUnsubscribe)
    {
        NSArray *keys = [_subscribed allKeysForObject:subscription];
        [_subscribed removeObjectsForKeys:keys];
    }

    return 0;
}

- (CNTServiceSubscription *) addSubscribe:(NSString *)event success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure
{
    if (_subscribed == nil)
        _subscribed = [[NSMutableDictionary alloc] init];

    CNTServiceSubscription *subscription = [_subscribed objectForKey:event];

    if (subscription == nil)
    {
        NSURL *eventURL = [NSURL URLWithString:lgeUDAPRequestURI[LGE_EVENT_REQUEST]];
        subscription = [CNTServiceSubscription subscriptionWithDelegate:self target:eventURL payload:nil callId:0];
        [_subscribed setObject:subscription forKey:event];
    }

    if (success)
        [subscription addSuccess:success];

    if (failure)
        [subscription addFailure:failure];

    if (![subscription isSubscribed])
        [subscription subscribe];

    return subscription;
}

- (CNTServiceSubscription *) killSubscribe:(NSString *)event
{
    CNTServiceSubscription *subscription = [_subscribed objectForKey:event];

    if (subscription)
        [_subscribed removeObjectForKey:event];

    return subscription;
}

@end
