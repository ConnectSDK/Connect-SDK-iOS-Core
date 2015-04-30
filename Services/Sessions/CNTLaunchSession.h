//
//  CNTLaunchSession.h
//  Connect SDK
//
//  Created by Jeremy White on 1/28/14.
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
#import "CNTJSONObjectCoding.h"

@class CNTDeviceService;


/*!
 * CNTLaunchSession type is used to help CNTDeviceService's know how to close a LunchSession.
 */
typedef enum
{
    /*! Unknown CNTLaunchSession type, may be unable to close this launch session */
    LaunchSessionTypeUnknown,

    /*! CNTLaunchSession represents a launched app */
    LaunchSessionTypeApp,

    /*! CNTLaunchSession represents an external input picker that was launched */
    LaunchSessionTypeExternalInputPicker,

    /*! CNTLaunchSession represents a media app */
    LaunchSessionTypeMedia,

    /*! CNTLaunchSession represents a web app */
    LaunchSessionTypeWebApp
} CNTLaunchSessionType;


/*!
 * Any time anything is launched onto a first screen device, there will be important session information that needs to be tracked. CNTLaunchSession will track this data, and must be retained to perform certain actions within the session.
 */
@interface CNTLaunchSession : NSObject <CNTJSONObjectCoding>

/*! System-specific, unique ID of the app (ex. youtube.leanback.v4, 0000134, hulu) */
@property (nonatomic, strong) NSString *appId;

/*! User-friendly name of the app (ex. YouTube, Browser, Hulu) */
@property (nonatomic, strong) NSString *name;

/*! Unique ID for the session (only provided by certain protocols) */
@property (nonatomic, strong) NSString *sessionId;

/*! Raw data from the first screen device about the session. In most cases, this is an NSDictionary. */
@property (nonatomic, strong) id rawData;

/*!
 * When closing a CNTLaunchSession, the CNTDeviceService relies on the sessionType to determine the method of closing the session.
 */
@property (nonatomic) CNTLaunchSessionType sessionType;

/*! CNTDeviceService responsible for launching the session. */
@property (nonatomic, weak) CNTDeviceService *service;

/*!
 * Compares two CNTLaunchSession objects.
 *
 * @param launchSession CNTLaunchSession object to compare.
 *
 * @return YES if both CNTLaunchSession id and sessionId values are equal
 */
- (BOOL)isEqual:(CNTLaunchSession *)launchSession;

/*!
 * Instantiates a CNTLaunchSession object for a given app ID.
 *
 * @param appId System-specific, unique ID of the app
 */
+ (CNTLaunchSession *) launchSessionForAppId:(NSString *)appId;

/*!
 * Closes the session on the first screen device. Depending on the sessionType, the associated service will have different ways of handling the close functionality.
 *
 * @param success (optional) SuccessBlock to be called on success
 * @param failure (optional) FailureBlock to be called on failure
 */
- (void) closeWithSuccess:(SuccessBlock)success failure:(FailureBlock)failure;

@end
