//
//  CNTWebAppLauncher.h
//  Connect SDK
//
//  Created by Jeremy White on 12/16/13.
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

#import <Foundation/Foundation.h>
#import "CNTCapability.h"
#import "CNTLaunchSession.h"
#import "CNTWebAppSession.h"
#import "CNTMediaControl.h"

#define kCNTWebAppLauncherAny @"CNTWebAppLauncher.Any"

#define kCNTWebAppLauncherLaunch @"CNTWebAppLauncher.Launch"
#define kCNTWebAppLauncherLaunchParams @"CNTWebAppLauncher.Launch.Params"
#define kCNTWebAppLauncherMessageSend @"CNTWebAppLauncher.Message.Send"
#define kCNTWebAppLauncherMessageReceive @"CNTWebAppLauncher.Message.Receive"
#define kCNTWebAppLauncherMessageSendJSON @"CNTWebAppLauncher.Message.Send.JSON"
#define kCNTWebAppLauncherMessageReceiveJSON @"CNTWebAppLauncher.Message.Receive.JSON"
#define kCNTWebAppLauncherConnect @"CNTWebAppLauncher.Connect"
#define kCNTWebAppLauncherDisconnect @"CNTWebAppLauncher.Disconnect"
#define kCNTWebAppLauncherJoin @"CNTWebAppLauncher.Join"
#define kCNTWebAppLauncherClose @"CNTWebAppLauncher.Close"
#define kCNTWebAppLauncherPin @"CNTWebAppLauncher.Pin"

#define kCNTWebAppLauncherCapabilities @[\
    kCNTWebAppLauncherLaunch,\
    kCNTWebAppLauncherLaunchParams,\
    kCNTWebAppLauncherMessageSend,\
    kCNTWebAppLauncherMessageReceive,\
    kCNTWebAppLauncherMessageSendJSON,\
    kCNTWebAppLauncherMessageReceiveJSON,\
    kCNTWebAppLauncherConnect,\
    kCNTWebAppLauncherDisconnect,\
    kCNTWebAppLauncherJoin,\
    kCNTWebAppLauncherClose,\
    kCNTWebAppLauncherPin\
]

@protocol CNTWebAppLauncher <NSObject>

/*!
 * Success block that is called upon successfully launch of a web app.
 *
 * @param webAppSession Object containing important information about the web app's session. This object is required to perform many functions with the web app, including app-to-app communication, media playback, closing, etc.
 */
typedef void (^CNTWebAppLaunchSuccessBlock)(CNTWebAppSession *webAppSession);

- (id<CNTWebAppLauncher>) webAppLauncher;
- (CNTCapabilityPriorityLevel) webAppLauncherPriority;

- (void) launchWebApp:(NSString *)webAppId success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;

/*!
 * This method requires pairing on webOS
 */
- (void) launchWebApp:(NSString *)webAppId relaunchIfRunning:(BOOL)relaunchIfRunning success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;

/*!
 * This method requires pairing on webOS
 */
- (void) launchWebApp:(NSString *)webAppId params:(NSDictionary *)params relaunchIfRunning:(BOOL)relaunchIfRunning success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) joinWebApp:(CNTLaunchSession *)webAppLaunchSession success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) joinWebAppWithId:(NSString *)webAppId success:(CNTWebAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) closeWebApp:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) pinWebApp:(NSString *)webAppId success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) unPinWebApp:(NSString *)webAppId success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) isWebAppPinned:(NSString *)webAppId success:(CNTWebAppPinStatusBlock)success failure:(CNTFailureBlock)failure;

- (CNTServiceSubscription *)subscribeIsWebAppPinned:(NSString*)webAppId success:(CNTWebAppPinStatusBlock)success failure:(CNTFailureBlock)failure;
@end
