//
//  CNTWebOSTVService.h
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

#define kCNTConnectSDKWebOSTVServiceId @"webOS TV"

#import <UIKit/UIKit.h>
#import "CNTDeviceService.h"
#import "CNTLauncher.h"
#import "CNTWebOSTVServiceConfig.h"
#import "CNTMediaPlayer.h"
#import "CNTVolumeControl.h"
#import "CNTTVControl.h"
#import "CNTKeyControl.h"
#import "CNTWebOSTVServiceMouse.h"
#import "CNTMouseControl.h"
#import "CNTPowerControl.h"
#import "CNTMediaControl.h"
#import "CNTWebAppLauncher.h"
#import "CNTToastControl.h"
#import "CNTExternalInputControl.h"
#import "CNTTextInputControl.h"

@class CNTWebOSWebAppSession;
@class CNTWebOSTVServiceSocketClient;

@interface CNTWebOSTVService : CNTDeviceService <CNTLauncher, CNTMediaPlayer, CNTMediaControl, CNTVolumeControl, CNTTVControl, CNTKeyControl, CNTMouseControl, CNTPowerControl, CNTWebAppLauncher, CNTExternalInputControl, CNTToastControl, CNTTextInputControl>

// @cond INTERNAL
typedef enum {
    CNT_LAUNCH = 0,
    CNT_LAUNCH_WEBAPP,
    CNT_APP_TO_APP,
    CNT_CONTROL_AUDIO,
    CNT_CONTROL_INPUT_MEDIA_PLAYBACK
} CNTWebOSTVServiceOpenPermission;

#define kCNTWebOSTVServiceOpenPermissions @[@"LAUNCH", @"LAUNCH_WEBAPP", @"APP_TO_APP", @"CONTROL_AUDIO", @"CONTROL_INPUT_MEDIA_PLAYBACK"]

typedef enum {
    CNT_CONTROL_POWER = 0,
    CNT_READ_INSTALLED_APPS,
    CNT_CONTROL_DISPLAY,
    CNT_CONTROL_INPUT_JOYSTICK,
    CNT_CONTROL_INPUT_MEDIA_RECORDING,
    CNT_CONTROL_INPUT_TV,
    CNT_READ_INPUT_DEVICE_LIST,
    CNT_READ_NETWORK_STATE,
    CNT_READ_TV_CHANNEL_LIST,
    CNT_WRITE_NOTIFICATION_TOAST
} CNTWebOSTVServiceProtectedPermission;

#define kCNTWebOSTVServiceProtectedPermissions @[@"CONTROL_POWER", @"READ_INSTALLED_APPS", @"CONTROL_DISPLAY", @"CONTROL_INPUT_JOYSTICK", @"CONTROL_INPUT_MEDIA_RECORDING", @"CONTROL_INPUT_TV", @"READ_INPUT_DEVICE_LIST", @"READ_NETWORK_STATE", @"READ_TV_CHANNEL_LIST", @"WRITE_NOTIFICATION_TOAST"]

typedef enum {
    CNT_CONTROL_INPUT_TEXT = 0,
    CNT_CONTROL_MOUSE_AND_KEYBOARD,
    CNT_READ_CURRENT_CHANNEL,
    CNT_READ_RUNNING_APPS
} CNTWebOSTVServicePersonalActivityPermission;

#define kCNTWebOSTVServicePersonalActivityPermissions @[@"CONTROL_INPUT_TEXT", @"CONTROL_MOUSE_AND_KEYBOARD", @"READ_CURRENT_CHANNEL", @"READ_RUNNING_APPS"]

@property (nonatomic, strong, readonly) CNTWebOSTVServiceSocketClient *socket;
@property (nonatomic, strong, readonly) CNTWebOSTVServiceMouse *mouseSocket;
/// The base class' @c serviceConfig property downcast to
/// @c CNTWebOSTVServiceConfig class if possible, or nil.
@property (nonatomic, strong, readonly) CNTWebOSTVServiceConfig *webOSTVServiceConfig;
@property (nonatomic, strong) NSArray *permissions;
@property (nonatomic, readonly) NSDictionary *appToAppIdMappings;
@property (nonatomic, readonly) NSDictionary *webAppSessions;
// @endcond

#pragma mark - Web app & app to app

// @cond INTERNAL
- (void) connectToWebApp:(CNTWebOSWebAppSession *)webAppSession joinOnly:(BOOL)joinOnly success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
// @endcond

#pragma mark - Native app to app

// @cond INTERNAL
- (void) connectToApp:(NSString *)appId success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) joinApp:(NSString *)appId success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) connectToApp:(CNTWebOSWebAppSession *)webAppSession joinOnly:(BOOL)joinOnly success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
// @endcond

#pragma mark - System Info

// @cond INTERNAL
typedef void (^ ServiceListSuccessBlock)(NSArray *serviceList);
typedef void (^ SystemInfoSuccessBlock)(NSArray *featureList);

- (void)getServiceListWithSuccess:(ServiceListSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void)getSystemInfoWithSuccess:(SystemInfoSuccessBlock)success failure:(CNTFailureBlock)failure;
// @endcond

@end
