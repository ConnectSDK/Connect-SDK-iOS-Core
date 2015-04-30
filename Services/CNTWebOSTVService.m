//
//  WebOSService.m
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

#import "CNTWebOSTVService.h"
#import "CNTConnectError.h"
#import "CNTDiscoveryManager.h"
#import "CNTServiceAsyncCommand.h"
#import "CNTWebOSWebAppSession.h"
#import "CNTWebOSTVServiceSocketClient.h"
#import "CTGuid.h"
#import "CommonMacros.h"

#define kKeyboardEnter @"\x1b ENTER \x1b"
#define kKeyboardDelete @"\x1b DELETE \x1b"

@interface CNTWebOSTVService () <UIAlertViewDelegate, WebOSTVServiceSocketClientDelegate>
{
    NSArray *_permissions;

    NSMutableDictionary *_webAppSessions;
    NSMutableDictionary *_appToAppIdMappings;

    NSTimer *_pairingTimer;
    UIAlertView *_pairingAlert;

    NSMutableArray *_keyboardQueue;
    BOOL _keyboardQueueProcessing;

    BOOL _mouseInit;
    UIAlertView *_pinAlertView;
}

@end

@implementation CNTWebOSTVService

@synthesize serviceDescription = _serviceDescription, pairingType = _pairingType;

#pragma mark - Setup

- (instancetype) initWithServiceConfig:(CNTServiceConfig *)serviceConfig
{
    self = [super init];

    if (self)
    {
        [self setServiceConfig:serviceConfig];
    }

    return self;
}

#pragma mark - Getters & Setters

- (void) setPairingType:(DeviceServicePairingType)pairingType {
    _pairingType = pairingType;
}

- (DeviceServicePairingType)pairingType{
    DeviceServicePairingType pairingType = DeviceServicePairingTypeNone;
    if ([CNTDiscoveryManager sharedManager].pairingLevel == CNTDeviceServicePairingLevelOn)
    {
        pairingType = _pairingType!=DeviceServicePairingTypeNone ? _pairingType : DeviceServicePairingTypeFirstScreen;
    }
    return pairingType;
}

- (CNTWebOSTVServiceConfig *)webOSTVServiceConfig {
    return ([self.serviceConfig isKindOfClass:[CNTWebOSTVServiceConfig class]] ?
            (CNTWebOSTVServiceConfig *)self.serviceConfig :
            nil);
}

#pragma mark - Inherited methods

- (void) setServiceConfig:(CNTServiceConfig *)serviceConfig
{
    const BOOL oldServiceConfigHasKey = (self.webOSTVServiceConfig.clientKey != nil);
    if ([serviceConfig isKindOfClass:[CNTWebOSTVServiceConfig class]])
    {
        const BOOL newServiceConfigHasKey = (((CNTWebOSTVServiceConfig *)serviceConfig).clientKey != nil);
        const BOOL wouldLoseKey = oldServiceConfigHasKey && !newServiceConfigHasKey;
        _CNT_assert_state(!wouldLoseKey, @"Losing important data!");

        [super setServiceConfig:serviceConfig];
    } else
    {
        _CNT_assert_state(!oldServiceConfigHasKey, @"Losing important data!");

        [super setServiceConfig:[[CNTWebOSTVServiceConfig alloc] initWithServiceConfig:serviceConfig]];
    }
}

- (void) setServiceDescription:(CNTServiceDescription *)serviceDescription
{
    _serviceDescription = serviceDescription;

    if (!self.serviceConfig.UUID)
        self.serviceConfig.UUID = serviceDescription.UUID;

    if (!_serviceDescription.locationResponseHeaders)
        return;

    NSString *serverInfo = [_serviceDescription.locationResponseHeaders objectForKey:@"Server"];
    NSString *systemOS = [[serverInfo componentsSeparatedByString:@" "] firstObject];
    NSString *systemVersion = [[systemOS componentsSeparatedByString:@"/"] lastObject];

    _serviceDescription.version = systemVersion;

    [self updateCapabilities];
}

- (CNTDeviceService *)dlnaService
{
    NSDictionary *allDevices = [[CNTDiscoveryManager sharedManager] allDevices];
    CNTConnectableDevice *device;
    CNTDeviceService *service;

    if (allDevices && allDevices.count > 0)
        device = [allDevices objectForKey:self.serviceDescription.address];

    if (device)
        service = [device serviceWithName:@"DLNA"];

    return service;
}

- (void) updateCapabilities
{
    NSArray *capabilities = [NSArray array];

    if ([CNTDiscoveryManager sharedManager].pairingLevel == CNTDeviceServicePairingLevelOn)
    {
        capabilities = [capabilities arrayByAddingObjectsFromArray:@[
                kKeyControlSendKeyCode,
                kKeyControlUp,
                kKeyControlDown,
                kKeyControlLeft,
                kKeyControlRight,
                kKeyControlHome,
                kKeyControlBack,
                kKeyControlOK
        ]];

        capabilities = [capabilities arrayByAddingObjectsFromArray:kMouseControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kTextInputControlCapabilities];
        capabilities = [capabilities arrayByAddingObject:kPowerControlOff];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaPlayerCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kLauncherCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kTVControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kExternalInputControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kVolumeControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kToastControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaControlCapabilities];
    } else
    {
        capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaPlayerCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:kVolumeControlCapabilities];
        capabilities = [capabilities arrayByAddingObjectsFromArray:@[
                kLauncherApp,
                kLauncherAppParams,
                kLauncherAppStore,
                kLauncherAppStoreParams
                kLauncherAppClose,
                kLauncherBrowser,
                kLauncherBrowserParams,
                kLauncherHulu,
                kLauncherNetflix,
                kLauncherNetflixParams,
                kLauncherYouTube,
                kLauncherYouTubeParams,
                kLauncherAppState,
                kLauncherAppStateSubscribe
        ]];
    }

    if (_serviceDescription && _serviceDescription.version)
    {
        if ([_serviceDescription.version rangeOfString:@"4.0.0"].location == NSNotFound && [_serviceDescription.version rangeOfString:@"4.0.1"].location == NSNotFound)
        {
            capabilities = [capabilities arrayByAddingObjectsFromArray:kWebAppLauncherCapabilities];
            capabilities = [capabilities arrayByAddingObjectsFromArray:kMediaControlCapabilities];
        } else
        {
            capabilities = [capabilities arrayByAddingObjectsFromArray:@[
                    kWebAppLauncherLaunch,
                    kWebAppLauncherLaunchParams,

                    kMediaControlPlay,
                    kMediaControlPause,
                    kMediaControlStop,
                    kMediaControlSeek,
                    kMediaControlPosition,
                    kMediaControlDuration,
                    kMediaControlPlayState,

                    kWebAppLauncherClose
            ]];
        }
    }

    [self setCapabilities:capabilities];
}

+ (NSDictionary *) discoveryParameters
{
    return @{
             @"serviceId": kConnectSDKWebOSTVServiceId,
             @"ssdp":@{
                     @"filter":@"urn:lge-com:service:webos-second-screen:1"
                  }
             };
}

- (BOOL) isConnectable
{
    return YES;
}

- (BOOL) connected
{
    if ([CNTDiscoveryManager sharedManager].pairingLevel == CNTDeviceServicePairingLevelOn)
        return self.socket.connected && (self.webOSTVServiceConfig.clientKey != nil);
    else
        return self.socket.connected;
}

- (void) connect
{
    if (!self.socket)
    {
        _socket = [[CNTWebOSTVServiceSocketClient alloc] initWithService:self];
        _socket.delegate = self;
    }

    if (!self.connected)
        [self.socket connect];
}

- (void) disconnect
{
    [self disconnectWithError:nil];
}

- (void) disconnectWithError:(NSError *)error
{
    [self.socket disconnectWithError:error];

    [_webAppSessions enumerateKeysAndObjectsUsingBlock:^(id key, CNTWebOSWebAppSession *session, BOOL *stop) {
        [session disconnectFromWebApp];
    }];

    _webAppSessions = [NSMutableDictionary new];
}

#pragma mark - Initial connection & pairing

- (BOOL) requiresPairing
{
    return [CNTDiscoveryManager sharedManager].pairingLevel == CNTDeviceServicePairingLevelOn;
}

#pragma mark - Paring alert

-(void) showAlert
{
    NSString *title = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_Title" value:@"Pairing with device" table:@"ConnectSDK"];
    NSString *message = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_Request" value:@"Please confirm the connection on your device" table:@"ConnectSDK"];
    NSString *ok = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_OK" value:@"OK" table:@"ConnectSDK"];
    NSString *cancel = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_Cancel" value:@"Cancel" table:@"ConnectSDK"];
    
    _pairingAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancel otherButtonTitles:ok, nil];
    if(self.pairingType == DeviceServicePairingTypePinCode || self.pairingType == DeviceServicePairingTypeMixed){
        _pairingAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        _pairingAlert.message = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_Request_Pin" value:@"Please enter the pin code" table:@"ConnectSDK"];
    }
    dispatch_on_main(^{ [_pairingAlert show]; });
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView == _pairingAlert){
        if (buttonIndex == 0){
            [self disconnect];
        }else
            if((self.pairingType == DeviceServicePairingTypePinCode || self.pairingType == DeviceServicePairingTypeMixed) && buttonIndex == 1){
                NSString *pairingCode = [alertView textFieldAtIndex:0].text;
                [self sendPairingKey:pairingCode success:nil failure:nil];
            }
    }
}

-(void) showAlertWithTitle:(NSString *)title andMessage:(NSString *)message
{
    NSString *alertTitle = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_Title" value:title table:@"ConnectSDK"];
    NSString *alertMessage = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_Request" value:message table:@"ConnectSDK"];
    NSString *ok = [[NSBundle mainBundle] localizedStringForKey:@"Connect_SDK_Pair_OK" value:@"OK" table:@"ConnectSDK"];
    if(!_pinAlertView){
        _pinAlertView = [[UIAlertView alloc] initWithTitle:alertTitle message:alertMessage delegate:self cancelButtonTitle:nil otherButtonTitles:ok, nil];
    }
    dispatch_on_main(^{ [_pinAlertView show]; });
}

-(void)dismissPinAlertView{
    if (_pinAlertView && _pinAlertView.isVisible){
        [_pinAlertView dismissWithClickedButtonIndex:0 animated:NO];
    }
}

#pragma mark - WebOSTVServiceSocketClientDelegate

- (void) socketWillRegister:(CNTWebOSTVServiceSocketClient *)socket
{
    _pairingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(showAlert) userInfo:nil repeats:NO];
}

- (void) socket:(CNTWebOSTVServiceSocketClient *)socket registrationFailed:(NSError *)error
{
    if (_pairingAlert && _pairingAlert.isVisible)
        dispatch_on_main(^{ [_pairingAlert dismissWithClickedButtonIndex:0 animated:NO]; });

    if (self.delegate && [self.delegate respondsToSelector:@selector(deviceService:pairingFailedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self pairingFailedWithError:error]; });

    [self disconnect];
}

- (void) socketDidConnect:(CNTWebOSTVServiceSocketClient *)socket
{
    [_pairingTimer invalidate];

    if (_pairingAlert && _pairingAlert.visible)
        dispatch_on_main(^{ [_pairingAlert dismissWithClickedButtonIndex:1 animated:YES]; });

    if ([self.delegate respondsToSelector:@selector(deviceServicePairingSuccess:)])
        dispatch_on_main(^{ [self.delegate deviceServicePairingSuccess:self]; });

    if ([self.delegate respondsToSelector:@selector(deviceServiceConnectionSuccess:)])
        dispatch_on_main(^{ [self.delegate deviceServiceConnectionSuccess:self]; });
}

- (void) socket:(CNTWebOSTVServiceSocketClient *)socket didFailWithError:(NSError *)error
{
    if (_pairingAlert && _pairingAlert.visible)
        dispatch_on_main(^{ [_pairingAlert dismissWithClickedButtonIndex:0 animated:YES]; });

    if ([self.delegate respondsToSelector:@selector(deviceService:didFailConnectWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self didFailConnectWithError:error]; });
}

- (void) socket:(CNTWebOSTVServiceSocketClient *)socket didCloseWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(deviceService:disconnectedWithError:)])
        dispatch_on_main(^{ [self.delegate deviceService:self disconnectedWithError:error]; });
}

#pragma mark - Helper methods

- (NSArray *)permissions
{
    if (_permissions)
        return _permissions;

    NSMutableArray *defaultPermissions = [[NSMutableArray alloc] init];
    [defaultPermissions addObjectsFromArray:kWebOSTVServiceOpenPermissions];

    if ([CNTDiscoveryManager sharedManager].pairingLevel == CNTDeviceServicePairingLevelOn)
    {
        [defaultPermissions addObjectsFromArray:kWebOSTVServiceProtectedPermissions];
        [defaultPermissions addObjectsFromArray:kWebOSTVServicePersonalActivityPermissions];
    }

    return [NSArray arrayWithArray:defaultPermissions];
}

- (void)setPermissions:(NSArray *)permissions
{
    _permissions = permissions;

    if (self.webOSTVServiceConfig.clientKey)
    {
        self.webOSTVServiceConfig.clientKey = nil;

        if (self.connected)
        {
            NSError *error = [CNTConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Permissions changed -- you will need to re-pair to the TV."];
            [self disconnectWithError:error];
        }
    }
}

+ (CNTChannelInfo *)channelInfoFromDictionary:(NSDictionary *)info
{
    CNTChannelInfo *channelInfo = [[CNTChannelInfo alloc] init];
    channelInfo.id = [info objectForKey:@"channelId"];
    channelInfo.name = [info objectForKey:@"channelName"];
    channelInfo.number = [info objectForKey:@"channelNumber"];
    channelInfo.majorNumber = [[info objectForKey:@"majorNumber"] intValue];
    channelInfo.minorNumber = [[info objectForKey:@"minorNumber"] intValue];
    channelInfo.rawData = [info copy];

    return channelInfo;
}

+ (CNTAppInfo *)appInfoFromDictionary:(NSDictionary *)info
{
    CNTAppInfo *appInfo = [[CNTAppInfo alloc] init];
    appInfo.name = [info objectForKey:@"title"];
    appInfo.id = [info objectForKey:@"id"];
    appInfo.rawData = [info copy];

    return appInfo;
}

+ (CNTExternalInputInfo *)externalInputInfoFromDictionary:(NSDictionary *)info
{
    CNTExternalInputInfo *externalInputInfo = [[CNTExternalInputInfo alloc] init];
    externalInputInfo.name = [info objectForKey:@"label"];
    externalInputInfo.id = [info objectForKey:@"id"];
    externalInputInfo.connected = [[info objectForKey:@"connected"] boolValue];
    externalInputInfo.iconURL = [NSURL URLWithString:[info objectForKey:@"icon"]];
    externalInputInfo.rawData = [info copy];

    return externalInputInfo;
}

#pragma mark - Launcher

- (id <CNTLauncher>)launcher
{
    return self;
}

- (CapabilityPriorityLevel) launcherPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)getAppListWithSuccess:(AppListSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.applicationManager/listApps"];

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        NSArray *foundApps = [responseDic objectForKey:@"apps"];
        NSMutableArray *appList = [[NSMutableArray alloc] init];

        [foundApps enumerateObjectsUsingBlock:^(NSDictionary *appInfo, NSUInteger idx, BOOL *stop)
        {
            [appList addObject:[CNTWebOSTVService appInfoFromDictionary:appInfo]];
        }];

        if (success)
            success(appList);
    };
    command.callbackError = failure;
    [command send];
}

- (void)launchApp:(NSString *)appId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchApplication:appId withParams:nil success:success failure:failure];
}

- (void)launchApplication:(NSString *)appId withParams:(NSDictionary *)params success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system.launcher/launch"];
    
    NSMutableDictionary *payload = [NSMutableDictionary new];

    [payload setValue:appId forKey:@"id"];

    if (params) {
        [payload setValue:params forKey:@"params"];

        NSString *contentId = [params objectForKey:@"contentId"];

        if (contentId)
            [payload setValue:contentId forKey:@"contentId"];
    }

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:appId];
        launchSession.sessionId = [responseObject objectForKey:@"sessionId"];
        launchSession.sessionType = LaunchSessionTypeApp;
        launchSession.service = self;
        launchSession.rawData = [responseObject copy];

        if (success)
            success(launchSession);
    };
    command.callbackError = failure;
    [command send];
}

- (void)launchAppWithInfo:(CNTAppInfo *)appInfo success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchApp:appInfo.id success:success failure:failure];
}

- (void)launchAppWithInfo:(CNTAppInfo *)appInfo params:(NSDictionary *)params success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchApplication:appInfo.id withParams:params success:success failure:failure];
}

- (void) launchAppStore:(NSString *)appId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    CNTAppInfo *appInfo = [CNTAppInfo appInfoForId:@"com.webos.app.discovery"];
    appInfo.name = @"LG Store";

    NSDictionary *params;

    if (appId && appId.length > 0)
    {
        NSString *query = [NSString stringWithFormat:@"category/GAME_APPS/%@", appId];
        params = @{ @"query" : query };
    }

    [self launchAppWithInfo:appInfo params:params success:success failure:failure];
}

- (void)launchBrowser:(NSURL *)target success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system.launcher/open"];
    NSDictionary *params = @{ @"target" : target.absoluteString };

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.socket target:URL payload:params];
    command.callbackComplete = ^(NSDictionary * responseObject)
    {
        CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:[responseObject objectForKey:@"id"]];
        launchSession.sessionId = [responseObject objectForKey:@"sessionId"];
        launchSession.sessionType = LaunchSessionTypeApp;
        launchSession.service = self;
        launchSession.rawData = [responseObject copy];

        if (success)
            success(launchSession);
    };
    command.callbackError = failure;
    [command send];
}

- (void)launchHulu:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSDictionary *params = @{ @"hulu" : contentId };
    
    [self launchApplication:@"hulu" withParams:params success:success failure:failure];
}

- (void)launchNetflix:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSString *netflixContentId = [NSString stringWithFormat:@"m=http%%3A%%2F%%2Fapi.netflix.com%%2Fcatalog%%2Ftitles%%2Fmovies%%2F%@&source_type=4", contentId];

    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:netflixContentId forKey:@"contentId"];

    [self launchApplication:@"netflix" withParams:params success:success failure:failure];
}

- (void)launchYouTube:(NSString *)contentId success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.launcher launchYouTube:contentId startTime:0.0 success:success failure:failure];
}

- (void) launchYouTube:(NSString *)contentId startTime:(float)startTime success:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    NSDictionary *params;

    if (contentId && contentId.length > 0)
    {
        if (startTime < 0.0)
        {
            if (failure)
                failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Start time may not be negative"]);

            return;
        }

        params = @{
            @"contentId" : [NSString stringWithFormat:@"%@&pairingCode=%@&t=%.1f", contentId, [[CTGuid randomGuid] stringValue], startTime]
        };
    }

    [self launchApplication:@"youtube.leanback.v4" withParams:params success:success failure:failure];
}

- (void) connectToApp:(NSString *)appId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:appId];
    launchSession.service = self;
    launchSession.sessionType = LaunchSessionTypeApp;

    CNTWebOSWebAppSession *webAppSession = [self webAppSessionForLaunchSession:launchSession];

    [self connectToApp:webAppSession joinOnly:NO success:^(id responseObject)
    {
        if (success)
            success(webAppSession);
    } failure:failure];
}

- (void) joinApp:(NSString *)appId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:appId];
    launchSession.service = self;
    launchSession.sessionType = LaunchSessionTypeApp;

    CNTWebOSWebAppSession *webAppSession = [self webAppSessionForLaunchSession:launchSession];

    [self connectToApp:webAppSession joinOnly:YES success:^(id responseObject)
    {
        if (success)
            success(webAppSession);
    } failure:failure];
}

- (void) connectToApp:(CNTWebOSWebAppSession *)webAppSession joinOnly:(BOOL)joinOnly success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self connectToWebApp:webAppSession joinOnly:joinOnly success:success failure:failure];
}

- (CNTServiceSubscription *)subscribeRunningAppWithSuccess:(AppInfoSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.applicationManager/getForegroundAppInfo"];

    CNTServiceSubscription *subscription = [self.socket addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
    {
        CNTAppInfo *appInfo = [[CNTAppInfo alloc] init];
        appInfo.id = [responseObject objectForKey:@"appId"];
        appInfo.rawData = [responseObject copy];

        if (success)
            success(appInfo);
    } failure:failure];

    return subscription;
}

- (void)getRunningAppWithSuccess:(AppInfoSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.applicationManager/getForegroundAppInfo"];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        CNTAppInfo *appInfo = [[CNTAppInfo alloc] init];
        appInfo.id = [responseObject objectForKey:@"appId"];
        appInfo.name = [responseObject objectForKey:@"appName"];
        appInfo.rawData = [responseObject copy];

        if (success)
            success(appInfo);
    };
    command.callbackError = failure;
    [command send];
}

- (void)getAppState:(CNTLaunchSession *)launchSession success:(AppStateSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system.launcher/getAppState"];

    NSMutableDictionary *params = [NSMutableDictionary new];
    if (launchSession && launchSession.appId) [params setValue:launchSession.appId forKey:@"appId"];
    if (launchSession && launchSession.sessionId) [params setValue:launchSession.sessionId forKey:@"sessionId"];

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.socket target:URL payload:params];
    command.callbackComplete = ^(NSDictionary * responseObject)
    {
        BOOL running = [[responseObject objectForKey:@"running"] boolValue];
        BOOL visible = [[responseObject objectForKey:@"visible"] boolValue];

        if (success)
            success(running, visible);
    };
    command.callbackError = failure;
    [command send];
}

- (CNTServiceSubscription *)subscribeAppState:(CNTLaunchSession *)launchSession success:(AppStateSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system.launcher/getAppState"];

    NSMutableDictionary *params = [NSMutableDictionary new];
    if (launchSession && launchSession.appId) [params setValue:launchSession.appId forKey:@"appId"];
    if (launchSession && launchSession.sessionId) [params setValue:launchSession.sessionId forKey:@"sessionId"];

    CNTServiceSubscription *subscription = [self.socket addSubscribe:URL payload:params success:^(NSDictionary *responseObject)
    {
        BOOL running = [[responseObject objectForKey:@"running"] boolValue];
        BOOL visible = [[responseObject objectForKey:@"visible"] boolValue];

        if (success)
            success(running, visible);
    } failure:failure];

    return subscription;
}

- (void)closeApp:(CNTLaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system.launcher/close"];

    NSMutableDictionary *payload = [NSMutableDictionary new];
    if (launchSession.appId) [payload setValue:launchSession.appId forKey:@"id"]; // yes, this is id not appId (groan)
    if (launchSession.sessionId) [payload setValue:launchSession.sessionId forKey:@"sessionId"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

#pragma mark - External Input Control

- (id<CNTExternalInputControl>)externalInputControl
{
    return self;
}

- (CapabilityPriorityLevel)externalInputControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)launchInputPickerWithSuccess:(AppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self launchApp:@"com.webos.app.inputpicker" success:success failure:failure];
}

- (void)closeInputPicker:(CNTLaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self.launcher closeApp:launchSession success:success failure:failure];
}

- (void)getExternalInputListWithSuccess:(ExternalInputListSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/getExternalInputList"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        NSArray *externalInputsData = [responseObject objectForKey:@"devices"];
        NSMutableArray *externalInputs = [[NSMutableArray alloc] init];

        [externalInputsData enumerateObjectsUsingBlock:^(NSDictionary *externalInputData, NSUInteger idx, BOOL *stop)
        {
            [externalInputs addObject:[CNTWebOSTVService externalInputInfoFromDictionary:externalInputData]];
        }];

        if (success)
            success(externalInputs);
    };
    command.callbackError = failure;
    [command send];
}

- (void)setExternalInput:(CNTExternalInputInfo *)externalInputInfo success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/switchInput"];

    NSMutableDictionary *payload = [NSMutableDictionary new];
    if (externalInputInfo && externalInputInfo.id) [payload setValue:externalInputInfo.id forKey:@"inputId"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

#pragma mark - Media Player

- (id <CNTMediaPlayer>)mediaPlayer
{
    return self;
}

- (CapabilityPriorityLevel)mediaPlayerPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)displayImage:(NSURL *)imageURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    CNTMediaInfo *mediaInfo = [[CNTMediaInfo alloc] initWithURL:imageURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;
    CNTImageInfo *imageInfo = [[CNTImageInfo alloc] initWithURL:iconURL type:ImageTypeThumb];
    [mediaInfo addImage:imageInfo];
    
    [self displayImageWithMediaInfo:mediaInfo success:^(CNTMediaLaunchObject *mediaLanchObject) {
        success(mediaLanchObject.session,mediaLanchObject.mediaControl);
    } failure:failure];
}

- (void) displayImage:(CNTMediaInfo *)mediaInfo
              success:(MediaPlayerDisplaySuccessBlock)success
              failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        CNTImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    [self displayImage:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType success:success failure:failure];
}

- (void) displayImageWithMediaInfo:(CNTMediaInfo *)mediaInfo success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        CNTImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    if ([self.serviceDescription.version isEqualToString:@"4.0.0"])
    {
        if (self.dlnaService)
        {
            id<CNTMediaPlayer> mediaPlayer;
            
            if ([self.dlnaService respondsToSelector:@selector(mediaPlayer)])
                mediaPlayer = [self.dlnaService performSelector:@selector(mediaPlayer)];
            
            if (mediaPlayer && [mediaPlayer respondsToSelector:@selector(playMedia:iconURL:title:description:mimeType:shouldLoop:success:failure:)])
            {
                [mediaPlayer displayImageWithMediaInfo:mediaInfo success:success failure:failure];
                return;
            }
        }
        
        NSDictionary *params = @{
                                 @"target" : ensureString(mediaInfo.url.absoluteString),
                                 @"iconSrc" : ensureString(iconURL.absoluteString),
                                 @"title" : ensureString(mediaInfo.title),
                                 @"description" : ensureString(mediaInfo.description),
                                 @"mimeType" : ensureString(mediaInfo.mimeType)
                                 };
        
        [self displayMediaWithParams:params success:success failure:failure];
    } else
    {
        NSString *webAppId = @"CNTMediaPlayer";
        
        WebAppLaunchSuccessBlock connectSuccess = ^(CNTWebAppSession *webAppSession)
        {
            CNTWebOSWebAppSession *session = (CNTWebOSWebAppSession *)webAppSession;
            [session.mediaPlayer displayImageWithMediaInfo:mediaInfo success:success failure:failure];
        };
        
        [self joinWebAppWithId:webAppId success:connectSuccess failure:^(NSError *error)
         {
             [self launchWebApp:webAppId success:connectSuccess failure:failure];
         }];
    }
}

- (void) playMedia:(NSURL *)mediaURL iconURL:(NSURL *)iconURL title:(NSString *)title description:(NSString *)description mimeType:(NSString *)mimeType shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    CNTMediaInfo *mediaInfo = [[CNTMediaInfo alloc] initWithURL:mediaURL mimeType:mimeType];
    mediaInfo.title = title;
    mediaInfo.description = description;
    CNTImageInfo *imageInfo = [[CNTImageInfo alloc] initWithURL:iconURL type:ImageTypeThumb];
    [mediaInfo addImage:imageInfo];
    
    [self playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop success:^(CNTMediaLaunchObject *mediaLanchObject) {
        success(mediaLanchObject.session,mediaLanchObject.mediaControl);
    } failure:failure];
}

- (void) playMedia:(CNTMediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerDisplaySuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        CNTImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    [self playMedia:mediaInfo.url iconURL:iconURL title:mediaInfo.title description:mediaInfo.description mimeType:mediaInfo.mimeType shouldLoop:shouldLoop success:success failure:failure];
}

- (void) playMediaWithMediaInfo:(CNTMediaInfo *)mediaInfo shouldLoop:(BOOL)shouldLoop success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *iconURL;
    if(mediaInfo.images){
        CNTImageInfo *imageInfo = [mediaInfo.images firstObject];
        iconURL = imageInfo.url;
    }
    
    if ([self.serviceDescription.version isEqualToString:@"4.0.0"])
    {
        if (self.dlnaService)
        {
            id<CNTMediaPlayer> mediaPlayer;
            
            if ([self.dlnaService respondsToSelector:@selector(mediaPlayer)])
                mediaPlayer = [self.dlnaService performSelector:@selector(mediaPlayer)];
            
            if (mediaPlayer && [mediaPlayer respondsToSelector:@selector(playMediaWithMediaInfo:shouldLoop:success:failure:)])
            {
                [mediaPlayer playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop success:success failure:failure];
                return;
            }
        }
        
        NSDictionary *params = @{
                                 @"target" : ensureString(mediaInfo.url.absoluteString),
                                 @"iconSrc" : ensureString(iconURL.absoluteString),
                                 @"title" : ensureString(mediaInfo.title),
                                 @"description" : ensureString(mediaInfo.description),
                                 @"mimeType" : ensureString(mediaInfo.mimeType),
                                 @"loop" : shouldLoop ? @"true" : @"false"
                                 };
        
        [self displayMediaWithParams:params success:success failure:failure];
    } else
    {
        NSString *webAppId = @"CNTMediaPlayer";
        
        WebAppLaunchSuccessBlock connectSuccess = ^(CNTWebAppSession *webAppSession)
        {
            CNTWebOSWebAppSession *session = (CNTWebOSWebAppSession *)webAppSession;
            [session.mediaPlayer playMediaWithMediaInfo:mediaInfo shouldLoop:shouldLoop success:success failure:failure];
        };
        
        [self joinWebAppWithId:webAppId success:connectSuccess failure:^(NSError *error)
         {
             [self launchWebApp:webAppId success:connectSuccess failure:failure];
         }];
    }
}

- (void)displayMediaWithParams:(NSDictionary *)params success:(MediaPlayerSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.viewer/open"];

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.socket target:URL payload:params];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:[responseObject objectForKey:@"id"]];
        launchSession.sessionId = [responseObject objectForKey:@"sessionId"];
        launchSession.sessionType = LaunchSessionTypeMedia;
        launchSession.service = self;
        launchSession.rawData = [responseObject copy];

        CNTMediaLaunchObject *launchObject = [[CNTMediaLaunchObject alloc] initWithLaunchSession:launchSession andMediaControl:self.mediaControl];
        if(success){
            success(launchObject);
        }
    };
    command.callbackError = failure;
    [command send];
}

- (void)closeMedia:(CNTLaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self closeApp:launchSession success:success failure:failure];
}

#pragma mark - Media Control

- (id <CNTMediaControl>)mediaControl
{
    return self;
}

- (CapabilityPriorityLevel)mediaControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)playWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/play"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)pauseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/pause"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)stopWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/stop"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)rewindWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/rewind"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)fastForwardWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://media.controls/fastForward"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)seek:(NSTimeInterval)position success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)getPlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (void)getPositionWithSuccess:(MediaPositionSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (CNTServiceSubscription *)subscribePlayStateWithSuccess:(MediaPlayStateSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (CNTServiceSubscription *)subscribeMediaInfoWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
    
    return nil;
}

#pragma mark - Volume

- (id <CNTVolumeControl>)volumeControl
{
    return self;
}

- (CapabilityPriorityLevel)volumeControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)getMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/getMute"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];

    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        BOOL mute = [[responseDic objectForKey:@"mute"] boolValue];

        if (success)
            success(mute);
    };

    command.callbackError = failure;
    [command send];
}

- (void)setMute:(BOOL)mute success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/setMute"];
    NSDictionary *payload = @{ @"mute" : @(mute) };

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];

    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/getVolume"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];

    command.callbackComplete = (^(NSDictionary *responseDic)
    {
        int fromString = [[responseDic objectForKey:@"volume"] intValue];
        float volVal = fromString / 100.0;

        if (success)
            success(volVal);
    });

    command.callbackError = failure;
    [command send];
}

- (void)setVolume:(float)volume success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/setVolume"];
    NSDictionary *payload = @{ @"volume" : @(roundf(volume * 100.0f)) };

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];

    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)volumeUpWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/volumeUp"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)volumeDownWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/volumeDown"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (CNTServiceSubscription *)subscribeMuteWithSuccess:(MuteSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/getMute"];

    CNTServiceSubscription *subscription = [self.socket addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
    {
        BOOL muteValue = [[responseObject valueForKey:@"mute"] boolValue];

        if (success)
            success(muteValue);
    } failure:failure];

    return subscription;
}

- (CNTServiceSubscription *)subscribeVolumeWithSuccess:(VolumeSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://audio/getVolume"];

    CNTServiceSubscription *subscription = [self.socket addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
    {
        float volumeValue = [[responseObject valueForKey:@"volume"] floatValue] / 100.0;

        if (success)
            success(volumeValue);
    } failure:failure];

    return subscription;
}

#pragma mark - TV

- (id <CNTTVControl>)tvControl
{
    return self;
}

- (CapabilityPriorityLevel)tvControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)getCurrentChannelWithSuccess:(CurrentChannelSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/getCurrentChannel"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseDic)
    {
        if (success)
            success([CNTWebOSTVService channelInfoFromDictionary:responseDic]);
    };
    command.callbackError = failure;
    [command send];
}

- (void)getChannelListWithSuccess:(ChannelListSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/getChannelList"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];

    command.callbackComplete = (^(NSDictionary *responseDic)
    {
        NSArray *channels = [responseDic objectForKey:@"channelList"];
        NSMutableArray *channelList = [[NSMutableArray alloc] init];

        [channels enumerateObjectsUsingBlock:^(NSDictionary *channelInfo, NSUInteger idx, BOOL *stop)
        {
            [channelList addObject:[CNTWebOSTVService channelInfoFromDictionary:channelInfo]];
        }];

        if (success)
            success([NSArray arrayWithArray:channelList]);
    });

    command.callbackError = failure;
    [command send];
}

- (CNTServiceSubscription *)subscribeCurrentChannelWithSuccess:(CurrentChannelSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/getCurrentChannel"];

    CNTServiceSubscription *subscription = [self.socket addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
    {
        CNTChannelInfo *channelInfo = [CNTWebOSTVService channelInfoFromDictionary:responseObject];

        if (success)
            success(channelInfo);
    } failure:failure];

    return subscription;
}

- (void)channelUpWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/channelUp"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)channelDownWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/channelDown"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)setChannel:(CNTChannelInfo *)channelInfo success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://tv/openChannel"];
    NSDictionary *payload = @{ @"channelId" : channelInfo.id};

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (void)getProgramInfoWithSuccess:(ProgramInfoSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (CNTServiceSubscription *)subscribeProgramInfoWithSuccess:(ProgramInfoSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (void)getProgramListWithSuccess:(ProgramListSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

- (CNTServiceSubscription *)subscribeProgramListWithSuccess:(ProgramListSuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);

    return nil;
}

- (void)get3DEnabledWithSuccess:(TV3DEnabledSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.tv.display/get3DStatus"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        NSDictionary *status3D = [responseObject objectForKey:@"status3D"];
        BOOL status = [[status3D objectForKey:@"status"] boolValue];

        if (success)
            success(status);
    };
    command.callbackError = failure;
    [command send];
}

- (void)set3DEnabled:(BOOL)enabled success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL;

    if (enabled)
        URL = [NSURL URLWithString:@"ssap://com.webos.service.tv.display/set3DOn"];
    else
        URL = [NSURL URLWithString:@"ssap://com.webos.service.tv.display/set3DOff"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

- (CNTServiceSubscription *)subscribe3DEnabledWithSuccess:(TV3DEnabledSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.tv.display/get3DStatus"];

    CNTServiceSubscription *subscription = [self.socket addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
    {
        NSDictionary *status3D = [responseObject objectForKey:@"status3D"];
        BOOL status = [[status3D objectForKey:@"status"] boolValue];

        if (success)
            success(status);
    } failure:failure];

    return subscription;
}

#pragma mark - Key Control

- (id <CNTKeyControl>) keyControl
{
    return self;
}

- (CapabilityPriorityLevel) keyControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void) sendMouseButton:(WebOSTVMouseButton)button success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.mouseSocket)
    {
        [self.mouseSocket button:button];

        if (success)
            success(nil);
    } else
    {
        [self.mouseControl connectMouseWithSuccess:^(id responseObject)
        {
            [self.mouseSocket button:button];

            if (success)
                success(nil);
        } failure:failure];
    }
}

- (void)upWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMouseButton:WebOSTVMouseButtonUp success:success failure:failure];
}

- (void)downWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMouseButton:WebOSTVMouseButtonDown success:success failure:failure];
}

- (void)leftWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMouseButton:WebOSTVMouseButtonLeft success:success failure:failure];
}

- (void)rightWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMouseButton:WebOSTVMouseButtonRight success:success failure:failure];
}

- (void)okWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.mouseSocket)
    {
        [self.mouseSocket click];

        if (success)
            success(nil);
    } else
    {
        [self.mouseControl connectMouseWithSuccess:^(id responseObject)
        {
            [self.mouseSocket click];

            if (success)
                success(nil);
        } failure:failure];
    }
}

- (void)backWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMouseButton:WebOSTVMouseButtonBack success:success failure:failure];
}

- (void)homeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self sendMouseButton:WebOSTVMouseButtonHome success:success failure:failure];
}

- (void)sendKeyCode:(NSUInteger)keyCode success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

#pragma mark - Mouse

- (id<CNTMouseControl>)mouseControl
{
    return self;
}

- (CapabilityPriorityLevel)mouseControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)connectMouseWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (_mouseSocket || _mouseInit)
        return;

    _mouseInit = YES;

    NSURL *commandURL = [NSURL URLWithString:@"ssap://com.webos.service.networkinput/getPointerInputSocket"];
    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.socket target:commandURL payload:nil];

    command.callbackComplete = (^(NSDictionary *responseDic)
    {
        NSString *socket = [responseDic objectForKey:@"socketPath"];
        _mouseSocket = [[CNTWebOSTVServiceMouse alloc] initWithSocket:socket success:success failure:failure];
    });
    command.callbackError = ^(NSError *error)
    {
        _mouseInit = NO;
        _mouseSocket = nil;

        if (failure)
            failure(error);
    };
    [command send];
}

- (void)disconnectMouse
{
    [_mouseSocket disconnect];
    _mouseSocket = nil;

    _mouseInit = NO;
}

- (void) move:(CGVector)distance success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.mouseSocket)
    {
        [self.mouseSocket move:distance];

        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"CNTMouseControl socket is not yet initialized."]);
    }
}

- (void) scroll:(CGVector)distance success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (self.mouseSocket)
    {
        [self.mouseSocket scroll:distance];

        if (success)
            success(nil);
    } else
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"CNTMouseControl socket is not yet initialized."]);
    }
}

- (void)clickWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [self okWithSuccess:success failure:failure];
}

#pragma mark - Power

- (id<CNTPowerControl>)powerControl
{
    return self;
}

- (CapabilityPriorityLevel)powerControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)powerOffWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system/turnOff"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:nil];

    command.callbackComplete = (^(NSDictionary *responseDic)
    {
        BOOL didTurnOff = [[responseDic objectForKey:@"returnValue"] boolValue];

        if (didTurnOff && success)
            success(nil);
        else if (failure)
            failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeTvError andDetails:nil]);
    });

    command.callbackError = failure;
    [command send];
}

- (void) powerOnWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (failure)
        failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeNotSupported andDetails:nil]);
}

#pragma mark - Web App Launcher

- (id <CNTWebAppLauncher>)webAppLauncher
{
    return self;
}

- (CapabilityPriorityLevel)webAppLauncherPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)launchWebApp:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId params:nil relaunchIfRunning:YES success:success failure:failure];
}

- (void)launchWebApp:(NSString *)webAppId relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    [self.webAppLauncher launchWebApp:webAppId params:nil relaunchIfRunning:relaunchIfRunning success:success failure:failure];
}

- (void)launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (!webAppId || webAppId.length == 0)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid web app id"]);

        return;
    }

    __block CNTWebOSWebAppSession *webAppSession = _webAppSessions[webAppId];

    NSURL *URL = [NSURL URLWithString:@"ssap://webapp/launchWebApp"];

    NSMutableDictionary *payload = [NSMutableDictionary new];
    if (webAppId) [payload setObject:webAppId forKey:@"webAppId"];
    if (params) [payload setObject:params forKey:@"urlParams"];

    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        CNTLaunchSession *launchSession;

        if (webAppSession)
            launchSession = webAppSession.launchSession;
        else
        {
            launchSession = [CNTLaunchSession launchSessionForAppId:webAppId];
            webAppSession = [[CNTWebOSWebAppSession alloc] initWithLaunchSession:launchSession service:self];
            _webAppSessions[webAppId] = webAppSession;
        }

        launchSession.sessionType = LaunchSessionTypeWebApp;
        launchSession.service = self;
        launchSession.sessionId = [responseObject objectForKey:@"sessionId"];
        launchSession.rawData = [responseObject copy];

        if (success)
            success(webAppSession);
    };
    command.callbackError = failure;
    [command send];
}

- (void)launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    if (!webAppId || webAppId.length == 0)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You need to provide a valid webAppId."]);

        return;
    }

    if (relaunchIfRunning)
        [self.webAppLauncher launchWebApp:webAppId params:params success:success failure:failure];
    else
    {
        [self.launcher getRunningAppWithSuccess:^(CNTAppInfo *appInfo)
        {
            // TODO: this will only work on native apps, currently
            if ([appInfo.id hasSuffix:webAppId])
            {
                CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:webAppId];
                launchSession.sessionType = LaunchSessionTypeWebApp;
                launchSession.service = self;
                launchSession.rawData = appInfo.rawData;

                CNTWebOSWebAppSession *webAppSession = [self webAppSessionForLaunchSession:launchSession];

                if (success)
                    success(webAppSession);
            } else
            {
                [self.webAppLauncher launchWebApp:webAppId params:params success:success failure:failure];
            }
        } failure:failure];
    }
}

- (void)closeWebApp:(CNTLaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!launchSession || !launchSession.appId || launchSession.appId.length == 0)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"Must provide a valid launch session object"]);

        return;
    }

    CNTWebOSWebAppSession *webAppSession = _webAppSessions[launchSession.appId];

    if (webAppSession && webAppSession.connected)
    {
        // This is a hack to enable closing of bridged web apps that we didn't open
        NSDictionary *closeCommand = @{
                @"contentType" : @"connectsdk.serviceCommand",
                @"serviceCommand" : @{
                        @"type" : @"close"
                }
        };

        [webAppSession sendJSON:closeCommand success:^(id responseObject)
        {
            [webAppSession disconnectFromWebApp];

            if (success)
                success(responseObject);
        } failure:^(NSError *closeError)
        {
            [webAppSession disconnectFromWebApp];

            if (failure)
                failure(closeError);
        }];
    } else
    {
        if (webAppSession)
            [webAppSession disconnectFromWebApp];

        NSURL *URL = [NSURL URLWithString:@"ssap://webapp/closeWebApp"];

        NSMutableDictionary *payload = [NSMutableDictionary new];
        if (launchSession.appId) [payload setValue:launchSession.appId forKey:@"webAppId"];
        if (launchSession.sessionId) [payload setValue:launchSession.sessionId forKey:@"sessionId"];

        CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
        command.callbackComplete = success;
        command.callbackError = failure;
        [command send];
    }
}

- (void)joinWebApp:(CNTLaunchSession *)webAppLaunchSession success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    CNTWebOSWebAppSession *webAppSession = [self webAppSessionForLaunchSession:webAppLaunchSession];

    [webAppSession joinWithSuccess:^(id responseObject)
    {
        if (success)
            success(webAppSession);
    } failure:failure];
}

- (void)joinWebAppWithId:(NSString *)webAppId success:(WebAppLaunchSuccessBlock)success failure:(FailureBlock)failure
{
    CNTLaunchSession *launchSession = [CNTLaunchSession launchSessionForAppId:webAppId];
    launchSession.sessionType = LaunchSessionTypeWebApp;
    launchSession.service = self;

    [self joinWebApp:launchSession success:success failure:failure];
}

- (void) connectToWebApp:(CNTWebOSWebAppSession *)webAppSession joinOnly:(BOOL)joinOnly success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!_webAppSessions)
        _webAppSessions = [NSMutableDictionary new];

    if (!_appToAppIdMappings)
        _appToAppIdMappings = [NSMutableDictionary new];

    if (!webAppSession || !webAppSession.launchSession)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid CNTLaunchSession object."]);
        return;
    }

    NSString *appId = webAppSession.launchSession.appId;
    NSString *idKey;

    if (webAppSession.launchSession.sessionType == LaunchSessionTypeWebApp)
        idKey = @"webAppId";
    else
        idKey = @"appId";

    if (!appId || appId.length == 0)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid web app session"]);

        return;
    }

    NSURL *URL = [NSURL URLWithString:@"ssap://webapp/connectToApp"];

    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setValue:appId forKey:idKey];

    FailureBlock connectFailure = ^(NSError *error)
    {
        [webAppSession disconnectFromWebApp];

        BOOL appChannelDidClose = [error.localizedDescription rangeOfString:@"app channel closed"].location != NSNotFound;

        if (appChannelDidClose)
        {
            if (webAppSession && webAppSession.delegate && [webAppSession.delegate respondsToSelector:@selector(webAppSessionDidDisconnect:)])
                [webAppSession.delegate webAppSessionDidDisconnect:webAppSession];
        } else
        {
            if (failure)
                failure(error);
        }
    };

    SuccessBlock connectSuccess = ^(id responseObject) {
        NSString *state = [responseObject objectForKey:@"state"];

        if (![state isEqualToString:@"CONNECTED"])
        {
            if (joinOnly && [state isEqualToString:@"WAITING_FOR_APP"])
            {
                if (connectFailure)
                    connectFailure([CNTConnectError generateErrorWithCode:ConnectStatusCodeError andDetails:@"Web app is not currently running"]);
            }

            return;
        }

        NSString *fullAppId = responseObject[@"appId"];

        if (fullAppId)
        {
            if (webAppSession.launchSession.sessionType == LaunchSessionTypeWebApp)
                _appToAppIdMappings[fullAppId] = appId;

            webAppSession.fullAppId = fullAppId;
        }

        if (success)
            success(responseObject);
    };
    
    CNTServiceSubscription *appToAppSubscription = [CNTServiceSubscription subscriptionWithDelegate:webAppSession.socket target:URL payload:payload callId:-1];
    [appToAppSubscription addSuccess:connectSuccess];
    [appToAppSubscription addFailure:connectFailure];
    
    webAppSession.appToAppSubscription = appToAppSubscription;
    [appToAppSubscription subscribe];
}


- (void) pinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!webAppId || webAppId.length == 0)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid web app id"]);
        
        return;
    }
    
    NSURL *URL = [NSURL URLWithString:@"ssap://webapp/pinWebApp"];
    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setObject:webAppId forKey:@"webAppId"];
     __weak typeof(self) weakSelf = self;
    __block CNTServiceSubscription *subscription = [self.socket addSubscribe:URL payload:payload success:^(NSDictionary *responseDict)
                                         {
                                             if([responseDict valueForKey:@"pairingType"]){
                                                [weakSelf showAlertWithTitle:@"Pin Web App" andMessage:@"Please confirm on your device"];
                                                 
                                             }
                                             else
                                             {
                                                 [weakSelf dismissPinAlertView];
                                                 [subscription unsubscribe];
                                                 success(responseDict);
                                             }
                                             
                                         }failure:^(NSError *error){
                                             [weakSelf dismissPinAlertView];
                                             [subscription unsubscribe];
                                             failure(error);
                                         }];
}

- (void)unPinWebApp:(NSString *)webAppId success:(SuccessBlock)success failure:(FailureBlock)failure
{
    if (!webAppId || webAppId.length == 0)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid web app id"]);
        
        return;
    }
    
    NSURL *URL = [NSURL URLWithString:@"ssap://webapp/removePinnedWebApp"];
    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setObject:webAppId forKey:@"webAppId"];
    
    __weak typeof(self) weakSelf = self;
    __block CNTServiceSubscription *subscription = [self.socket addSubscribe:URL payload:payload success:^(NSDictionary *responseDict)
                                         {
                                             if([responseDict valueForKey:@"pairingType"]){
                                                [weakSelf showAlertWithTitle:@"Un Pin Web App" andMessage:@"Please confirm on your device"];
                                                
                                             }
                                             else
                                             {
                                                 [weakSelf dismissPinAlertView];
                                                 [subscription unsubscribe];
                                                  success(responseDict);
                                             }
                                             
                                             
                                         }failure:^(NSError *error){
                                             [weakSelf dismissPinAlertView];
                                             [subscription unsubscribe];
                                             failure(error);
                                         }];
}

- (void)isWebAppPinned:(NSString *)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
    if (!webAppId || webAppId.length == 0)
    {
        if (failure)
            failure([CNTConnectError generateErrorWithCode:ConnectStatusCodeArgumentError andDetails:@"You must provide a valid web app id"]);
        
        return;
    }
    NSURL *URL = [NSURL URLWithString:@"ssap://webapp/isWebAppPinned"];
    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setObject:webAppId forKey:@"webAppId"];
    
    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = (^(NSDictionary *responseDic)
                                {
                                    BOOL status = [[responseDic objectForKey:@"pinned"] boolValue];
                                    if(success){
                                        success(status);
                                    }
                                    
                                });
    command.callbackError = failure;
    [command send];
}

- (CNTServiceSubscription *)subscribeIsWebAppPinned:(NSString*)webAppId success:(WebAppPinStatusBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://webapp/isWebAppPinned"];
    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setObject:webAppId forKey:@"webAppId"];
    
    CNTServiceSubscription *subscription = [self.socket addSubscribe:URL payload:payload success:^(NSDictionary *responseObject)
                                         {
                                             BOOL status = [[responseObject objectForKey:@"pinned"] boolValue];
                                             if (success){
                                                 success(status);
                                             }
                                             
                                         } failure:failure];    
    return subscription;
}

- (void)sendPairingKey:(NSString *)pairingKey success:(SuccessBlock)success failure:(FailureBlock)failure {
   
    NSURL *URL = [NSURL URLWithString:@"ssap://pairing/setPin"];
    NSMutableDictionary *payload = [NSMutableDictionary new];
    [payload setObject:pairingKey forKey:@"pin"];
    
    CNTServiceCommand *command = [CNTServiceAsyncCommand commandWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = (^(NSDictionary *responseDic)
                                {
                                    if (success) {
                                        success(responseDic);
                                    }
                                    
                                });
    command.callbackError = ^(NSError *error){
                                if(failure){
                                    failure(error);
                                }
                            };
    [command send];
}

- (CNTWebOSWebAppSession *) webAppSessionForLaunchSession:(CNTLaunchSession *)launchSession
{
    if (!_webAppSessions)
        _webAppSessions = [NSMutableDictionary new];

    if (!launchSession.service)
        launchSession.service = self;

    CNTWebOSWebAppSession *webAppSession = _webAppSessions[launchSession.appId];

    if (!webAppSession)
    {
        webAppSession = [[CNTWebOSWebAppSession alloc] initWithLaunchSession:launchSession service:self];
        _webAppSessions[launchSession.appId] = webAppSession;
    }

    return webAppSession;
}

- (NSDictionary *) appToAppIdMappings
{
    return [NSDictionary dictionaryWithDictionary:_appToAppIdMappings];
}

- (NSDictionary *) webAppSessions
{
    return [NSDictionary dictionaryWithDictionary:_webAppSessions];
}

#pragma mark - Text Input Control

- (id<CNTTextInputControl>) textInputControl
{
    return self;
}

- (CapabilityPriorityLevel) textInputControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void) sendText:(NSString *)input success:(SuccessBlock)success failure:(FailureBlock)failure
{
    [_keyboardQueue addObject:input];

    if (!_keyboardQueueProcessing)
        [self sendKeys];
}

- (void)sendEnterWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [_keyboardQueue addObject:kKeyboardEnter];

    if (!_keyboardQueueProcessing)
        [self sendKeys];
}

- (void)sendDeleteWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure
{
    [_keyboardQueue addObject:kKeyboardDelete];

    if (!_keyboardQueueProcessing)
        [self sendKeys];
}

- (void) sendKeys
{
    _keyboardQueueProcessing = YES;

    NSString *target;
    NSString *key = [_keyboardQueue firstObject];
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];

    if ([key isEqualToString:kKeyboardEnter])
    {
        [_keyboardQueue removeObjectAtIndex:0];
        target = @"ssap://com.webos.service.ime/sendEnterKey";
    } else if ([key isEqualToString:kKeyboardDelete])
    {
        target = @"ssap://com.webos.service.ime/deleteCharacters";

        int count = 0;

        for (NSUInteger i = 0; i < _keyboardQueue.count; i++)
        {
            if ([[_keyboardQueue objectAtIndex:i] isEqualToString:kKeyboardDelete]) {
                count++;
            } else {
                break;
            }
        }

        NSRange deleteRange = NSMakeRange(0, count);
        [_keyboardQueue removeObjectsInRange:deleteRange];

        [payload setObject:@(count) forKey:@"count"];
    } else
    {
        target = @"ssap://com.webos.service.ime/insertText";
        NSMutableString *stringToSend = [[NSMutableString alloc] init];

        int count = 0;

        for (NSUInteger i = 0; i < _keyboardQueue.count; i++)
        {
            NSString *text = [_keyboardQueue objectAtIndex:i];

            if (![text isEqualToString:kKeyboardEnter] && ![text isEqualToString:kKeyboardDelete]) {
                [stringToSend appendString:text];
                count++;
            } else {
                break;
            }
        }

        NSRange textRange = NSMakeRange(0, count);
        [_keyboardQueue removeObjectsInRange:textRange];

        [payload setObject:stringToSend forKey:@"text"];
        [payload setObject:@(NO) forKey:@"replace"];
    }

    NSURL *URL = [NSURL URLWithString:target];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self.socket target:URL payload:payload];
    command.callbackComplete = ^(id responseObject)
    {
        _keyboardQueueProcessing = NO;

        if (_keyboardQueue.count > 0)
            [self sendKeys];
    };
    command.callbackError = ^(NSError *error)
    {
        _keyboardQueueProcessing = NO;

        if (_keyboardQueue.count > 0)
            [self sendKeys];
    };
    [command send];
}

- (CNTServiceSubscription *) subscribeTextInputStatusWithSuccess:(TextInputStatusInfoSuccessBlock)success failure:(FailureBlock)failure
{
    _keyboardQueue = [[NSMutableArray alloc] init];
    _keyboardQueueProcessing = NO;

    NSURL *URL = [NSURL URLWithString:@"ssap://com.webos.service.ime/registerRemoteKeyboard"];

    CNTServiceSubscription *subscription = [self.socket addSubscribe:URL payload:nil success:^(NSDictionary *responseObject)
    {
        BOOL isVisible = [[[responseObject objectForKey:@"currentWidget"] objectForKey:@"focus"] boolValue];
        NSString *type = [[responseObject objectForKey:@"currentWidget"] objectForKey:@"contentType"];

        UIKeyboardType keyboardType = UIKeyboardTypeDefault;

        if ([type isEqualToString:@"url"])
            keyboardType = UIKeyboardTypeURL;
        else if ([type isEqualToString:@"number"])
            keyboardType = UIKeyboardTypeNumberPad;
        else if ([type isEqualToString:@"phonenumber"])
            keyboardType = UIKeyboardTypeNamePhonePad;
        else if ([type isEqualToString:@"email"])
            keyboardType = UIKeyboardTypeEmailAddress;

        CNTTextInputStatusInfo *keyboardInfo = [[CNTTextInputStatusInfo alloc] init];
        keyboardInfo.isVisible = isVisible;
        keyboardInfo.keyboardType = keyboardType;
        keyboardInfo.rawData = [responseObject copy];

        if (success)
            success(keyboardInfo);
    } failure:failure];

    return subscription;
}

#pragma mark - Toast Control

- (id<CNTToastControl>)toastControl
{
    return self;
}

- (CapabilityPriorityLevel)toastControlPriority
{
    return CapabilityPriorityLevelHigh;
}

- (void)showToast:(NSString *)message success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (message) [params setValue:message forKey:@"message"];

    [self showToastWithParams:params success:success failure:failure];
}

- (void)showToast:(NSString *)message iconData:(NSString *)iconData iconExtension:(NSString *)iconExtension success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (message) [params setValue:message forKey:@"message"];
    if (iconData) [params setValue:iconData forKey:@"iconData"];
    if (iconExtension) [params setValue:iconExtension forKey:@"iconExtension"];

    [self showToastWithParams:params success:success failure:failure];
}

- (void)showClickableToast:(NSString *)message appInfo:(CNTAppInfo *)appInfo params:(NSDictionary *)launchParams success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (message) [params setValue:message forKey:@"message"];
    if (appInfo) [params setValue:appInfo.id forKey:@"target"];
    if (launchParams) [params setValue:launchParams forKey:@"params"];

    [self showToastWithParams:params success:success failure:failure];
}

- (void)showClickableToast:(NSString *)message appInfo:(CNTAppInfo *)appInfo params:(NSDictionary *)launchParams iconData:(NSString *)iconData iconExtension:(NSString *)iconExtension success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (message) [params setValue:message forKey:@"message"];
    if (appInfo) [params setValue:appInfo.id forKey:@"target"];
    if (launchParams) [params setValue:launchParams forKey:@"params"];
    if (iconData) [params setValue:iconData forKey:@"iconData"];
    if (iconExtension) [params setValue:iconExtension forKey:@"iconExtension"];

    [self showToastWithParams:params success:success failure:failure];
}

- (void)showClickableToast:(NSString *)message URL:(NSURL *)URL success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (message) [params setValue:message forKey:@"message"];
    if (URL) [params setValue:URL.absoluteString forKey:@"target"];

    [self showToastWithParams:params success:success failure:failure];
}

- (void)showClickableToast:(NSString *)message URL:(NSURL *)URL iconData:(NSString *)iconData iconExtension:(NSString *)iconExtension success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    if (message) [params setValue:message forKey:@"message"];
    if (URL) [params setValue:URL.absoluteString forKey:@"target"];
    if (iconData) [params setValue:iconData forKey:@"iconData"];
    if (iconExtension) [params setValue:iconExtension forKey:@"iconExtension"];

    [self showToastWithParams:params success:success failure:failure];
}

- (void) showToastWithParams:(NSDictionary *)params success:(SuccessBlock)success failure:(FailureBlock)failure
{
    NSMutableDictionary *toastParams = [NSMutableDictionary dictionaryWithDictionary:params];

    if ([toastParams objectForKey:@"iconData"] == nil)
    {
        NSString *imageName = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIconFiles"] objectAtIndex:0];

        if (imageName == nil)
            imageName = [[[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIcons"] objectForKey:@"CFBundlePrimaryIcon"] objectForKey:@"CFBundleIconFiles"] firstObject];

        UIImage *appIcon = [UIImage imageNamed:imageName];
        NSString *dataString;

        if (appIcon)
            dataString = [UIImagePNGRepresentation(appIcon) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];

        if (dataString)
        {
            [toastParams setObject:dataString forKey:@"iconData"];
            [toastParams setObject:@"png" forKey:@"iconExtension"];
        }
    }

    CNTServiceCommand *command = [[CNTServiceCommand alloc] initWithDelegate:self.socket target:[NSURL URLWithString:@"ssap://system.notifications/createToast"] payload:toastParams];
    command.callbackComplete = success;
    command.callbackError = failure;
    [command send];
}

#pragma mark - System info

- (void)getServiceListWithSuccess:(ServiceListSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://api/getServiceList"];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        NSArray *services = [responseObject objectForKey:@"services"];

        if (success)
            success(services);
    };
    command.callbackError = failure;
    [command send];
}

- (void)getSystemInfoWithSuccess:(SystemInfoSuccessBlock)success failure:(FailureBlock)failure
{
    NSURL *URL = [NSURL URLWithString:@"ssap://system/getSystemInfo"];

    CNTServiceCommand *command = [CNTServiceCommand commandWithDelegate:self.socket target:URL payload:nil];
    command.callbackComplete = ^(NSDictionary *responseObject)
    {
        NSArray *features = [responseObject objectForKey:@"features"];

        if (success)
            success(features);
    };
    command.callbackError = failure;
    [command send];
}

@end
