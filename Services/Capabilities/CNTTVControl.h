//
//  CNTTVControl.h
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
#import "CNTChannelInfo.h"
#import "CNTProgramInfo.h"
#import "CNTServiceSubscription.h"

#define kCNTTVControlAny @"CNTTVControl.Any"

#define kCNTTVControlChannelGet @"CNTTVControl.Channel.Get"
#define kCNTTVControlChannelSet @"CNTTVControl.Channel.Set"
#define kCNTTVControlChannelUp @"CNTTVControl.Channel.Up"
#define kCNTTVControlChannelDown @"CNTTVControl.Channel.Down"
#define kCNTTVControlChannelList @"CNTTVControl.Channel.List"
#define kCNTTVControlChannelSubscribe @"CNTTVControl.Channel.Subscribe"
#define kCNTTVControlProgramGet @"CNTTVControl.Program.Get"
#define kCNTTVControlProgramList @"CNTTVControl.Program.List"
#define kCNTTVControlProgramSubscribe @"CNTTVControl.Program.Subscribe"
#define kCNTTVControlProgramListSubscribe @"CNTTVControl.Program.List.Subscribe"
#define kCNTTVControl3DGet @"CNTTVControl.3D.Get"
#define kCNTTVControl3DSet @"CNTTVControl.3D.Set"
#define kCNTTVControl3DSubscribe @"CNTTVControl.3D.Subscribe"

#define kCNTTVControlCapabilities @[\
    kCNTTVControlChannelGet,\
    kCNTTVControlChannelSet,\
    kCNTTVControlChannelUp,\
    kCNTTVControlChannelDown,\
    kCNTTVControlChannelList,\
    kCNTTVControlChannelSubscribe,\
    kCNTTVControlProgramGet,\
    kCNTTVControlProgramList,\
    kCNTTVControlProgramSubscribe,\
    kCNTTVControlProgramListSubscribe,\
    kCNTTVControl3DGet,\
    kCNTTVControl3DSet,\
    kCNTTVControl3DSubscribe\
]

@protocol CNTTVControl <NSObject>

/*!
 * Success block that is called upon successfully getting the current channel's information.
 *
 * @param channelInfo Object containing information about the current channel
 */
typedef void (^CNTCurrentChannelSuccessBlock)(CNTChannelInfo *channelInfo);

/*!
 * Success block that is called upon successfully getting the channel list.
 *
 * @param channelList Array containing a CNTChannelInfo object for each available channel on the TV
 */
typedef void (^CNTChannelListSuccessBlock)(NSArray *channelList);

/*!
 * Success block that is called upon successfully getting the current program's information.
 *
 * @param programInfo Object containing information about the current program
 */
typedef void (^CNTProgramInfoSuccessBlock)(CNTProgramInfo *programInfo);

/*!
 * Success block that is called upon successfully getting the program list for the current channel.
 *
 * @param programList Array containing a CNTProgramInfo object for each available program on the TV's current channel
 */
typedef void (^CNTProgramListSuccessBlock)(NSArray *programList);

/*!
 * Success block that is called upon successfully getting the TV's 3D mode
 *
 * @param tv3DEnabled Whether 3D mode is currently enabled on the TV
 */
typedef void (^CNTTV3DEnabledSuccessBlock)(BOOL tv3DEnabled);

- (id<CNTTVControl>)tvControl;
- (CNTCapabilityPriorityLevel)tvControlPriority;

#pragma mark Set channel
- (void) channelUpWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock) failure;
- (void) channelDownWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock) failure;
- (void) setChannel:(CNTChannelInfo *)channelInfo success:(CNTSuccessBlock)success failure:(CNTFailureBlock) failure;

#pragma mark Channel Info
- (void) getCurrentChannelWithSuccess:(CNTCurrentChannelSuccessBlock)success failure:(CNTFailureBlock) failure;
- (CNTServiceSubscription *)subscribeCurrentChannelWithSuccess:(CNTCurrentChannelSuccessBlock)success failure:(CNTFailureBlock) failure;
- (void) getChannelListWithSuccess:(CNTChannelListSuccessBlock)success failure:(CNTFailureBlock) failure;

#pragma mark Program Info
- (void) getProgramInfoWithSuccess:(CNTProgramInfoSuccessBlock)success failure:(CNTFailureBlock) failure;
- (CNTServiceSubscription *)subscribeProgramInfoWithSuccess:(CNTProgramInfoSuccessBlock)success failure:(CNTFailureBlock) failure;

- (void) getProgramListWithSuccess:(CNTProgramListSuccessBlock)success failure:(CNTFailureBlock) failure;
- (CNTServiceSubscription *)subscribeProgramListWithSuccess:(CNTProgramListSuccessBlock)success failure:(CNTFailureBlock) failure;

#pragma mark 3D mode
- (void) get3DEnabledWithSuccess:(CNTTV3DEnabledSuccessBlock)success failure:(CNTFailureBlock) failure;
- (void) set3DEnabled:(BOOL)enabled success:(CNTSuccessBlock)success failure:(CNTFailureBlock) failure;
- (CNTServiceSubscription *) subscribe3DEnabledWithSuccess:(CNTTV3DEnabledSuccessBlock)success failure:(CNTFailureBlock) failure;

@end
