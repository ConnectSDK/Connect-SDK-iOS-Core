//
//  CNTLauncher.h
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
#import "CNTAppInfo.h"
#import "CNTServiceSubscription.h"
#import "CNTLaunchSession.h"

#define kCNTLauncherAny @"CNTLauncher.Any"

#define kCNTLauncherApp @"CNTLauncher.App"
#define kCNTLauncherAppParams @"CNTLauncher.App.Params"
#define kCNTLauncherAppClose @"CNTLauncher.App.Close"
#define kCNTLauncherAppList @"CNTLauncher.App.List"
#define kCNTLauncherAppStore @"CNTLauncher.AppStore"
#define kCNTLauncherAppStoreParams @"CNTLauncher.AppStore.Params"
#define kCNTLauncherBrowser @"CNTLauncher.Browser"
#define kCNTLauncherBrowserParams @"CNTLauncher.Browser.Params"
#define kCNTLauncherHulu @"CNTLauncher.Hulu"
#define kCNTLauncherHuluParams @"CNTLauncher.Hulu.Params"
#define kCNTLauncherNetflix @"CNTLauncher.Netflix"
#define kCNTLauncherNetflixParams @"CNTLauncher.Netflix.Params"
#define kCNTLauncherYouTube @"CNTLauncher.YouTube"
#define kCNTLauncherYouTubeParams @"CNTLauncher.YouTube.Params"
#define kCNTLauncherAppState @"CNTLauncher.AppState"
#define kCNTLauncherAppStateSubscribe @"CNTLauncher.AppState.Subscribe"
#define kCNTLauncherRunningApp @"CNTLauncher.RunningApp"
#define kCNTLauncherRunningAppSubscribe @"CNTLauncher.RunningApp.Subscribe"

#define kCNTLauncherCapabilities @[\
    kCNTLauncherApp,\
    kCNTLauncherAppParams,\
    kCNTLauncherAppClose,\
    kCNTLauncherAppList,\
    kCNTLauncherAppStore,\
    kCNTLauncherAppStoreParams,\
    kCNTLauncherBrowser,\
    kCNTLauncherBrowserParams,\
    kCNTLauncherHulu,\
    kCNTLauncherHuluParams,\
    kCNTLauncherNetflix,\
    kCNTLauncherNetflixParams,\
    kCNTLauncherYouTube,\
    kCNTLauncherYouTubeParams,\
    kCNTLauncherAppState,\
    kCNTLauncherAppStateSubscribe,\
    kCNTLauncherRunningApp,\
    kCNTLauncherRunningAppSubscribe\
]

@protocol CNTLauncher <NSObject>

/*!
 * Success block that is called upon requesting info about the current running app.
 *
 * @param appInfo Object containing info about the running app
 */
typedef void (^CNTAppInfoSuccessBlock)(CNTAppInfo *appInfo);

/*!
 * Success block that is called upon successfully launching an app.
 *
 * @param CNTLaunchSession Object containing important information about the app's launch session
 */
typedef void (^CNTAppLaunchSuccessBlock)(CNTLaunchSession *launchSession);

/*!
 * Success block that is called upon successfully getting the app list.
 *
 * @param appList Array containing an CNTAppInfo object for each available app on the device
 */
typedef void (^CNTAppListSuccessBlock)(NSArray *appList);

/*!
 * Success block that is called upon successfully getting an app's state.
 *
 * @param running Whether the app is currently running
 * @param visible Whether the app is currently visible on the screen
 */
typedef void (^CNTAppStateSuccessBlock)(BOOL running, BOOL visible);

- (id<CNTLauncher>) launcher;
- (CNTCapabilityPriorityLevel) launcherPriority;

#pragma mark Launch & close
- (void)launchApp:(NSString *)appId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void)launchAppWithInfo:(CNTAppInfo *)appInfo success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void)launchAppWithInfo:(CNTAppInfo *)appInfo params:(NSDictionary *)params success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void)closeApp:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

#pragma mark App Info
- (void) getAppListWithSuccess:(CNTAppListSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) getRunningAppWithSuccess:(CNTAppInfoSuccessBlock)success failure:(CNTFailureBlock)failure;
- (CNTServiceSubscription *)subscribeRunningAppWithSuccess:(CNTAppInfoSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void)getAppState:(CNTLaunchSession *)launchSession success:(CNTAppStateSuccessBlock)success failure:(CNTFailureBlock)failure;
- (CNTServiceSubscription *)subscribeAppState:(CNTLaunchSession *)launchSession success:(CNTAppStateSuccessBlock)success failure:(CNTFailureBlock)failure;

#pragma mark Helpers for deep linking
- (void)launchAppStore:(NSString *)appId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void)launchBrowser:(NSURL *)target success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void)launchYouTube:(NSString *)contentId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void)launchYouTube:(NSString *)contentId startTime:(float)startTime success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;

// TODO: add app store deep linking

// @cond INTERNAL
- (void)launchNetflix:(NSString *)contentId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void)launchHulu:(NSString *)contentId success:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;
// @endcond

@end
