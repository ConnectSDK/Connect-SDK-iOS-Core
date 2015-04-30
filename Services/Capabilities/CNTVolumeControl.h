//
//  CNTVolumeControl.h
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
#import "CNTServiceSubscription.h"

#define kCNTVolumeControlAny @"CNTVolumeControl.Any"

#define kCNTVolumeControlVolumeGet @"CNTVolumeControl.Get"
#define kCNTVolumeControlVolumeSet @"CNTVolumeControl.Set"
#define kCNTVolumeControlVolumeUpDown @"CNTVolumeControl.UpDown"
#define kCNTVolumeControlVolumeSubscribe @"CNTVolumeControl.Subscribe"
#define kCNTVolumeControlMuteGet @"CNTVolumeControl.Mute.Get"
#define kCNTVolumeControlMuteSet @"CNTVolumeControl.Mute.Set"
#define kCNTVolumeControlMuteSubscribe @"CNTVolumeControl.Mute.Subscribe"

#define kCNTVolumeControlCapabilities @[\
    kCNTVolumeControlVolumeGet,\
    kCNTVolumeControlVolumeSet,\
    kCNTVolumeControlVolumeUpDown,\
    kCNTVolumeControlVolumeSubscribe,\
    kCNTVolumeControlMuteGet,\
    kCNTVolumeControlMuteSet,\
    kCNTVolumeControlMuteSubscribe\
]

@protocol CNTVolumeControl <NSObject>

/*!
 * Success block that is called upon successfully getting the device's system volume.
 *
 * @param volume Current system volume, value is a float between 0.0 and 1.0
 */
typedef void (^CNTVolumeSuccessBlock)(float volume);

/*!
 * Success block that is called upon successfully getting the device's system mute status.
 *
 * @param mute Current system mute status
 */
typedef void (^CNTMuteSuccessBlock)(BOOL mute);

- (id<CNTVolumeControl>)volumeControl;
- (CNTCapabilityPriorityLevel)volumeControlPriority;

#pragma mark Volume
- (void) volumeUpWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) volumeDownWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) getVolumeWithSuccess:(CNTVolumeSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) setVolume:(float)volume success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

- (CNTServiceSubscription *)subscribeVolumeWithSuccess:(CNTVolumeSuccessBlock)success failure:(CNTFailureBlock)failure;

#pragma mark Mute
- (void) getMuteWithSuccess:(CNTMuteSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) setMute:(BOOL)mute success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

- (CNTServiceSubscription *)subscribeMuteWithSuccess:(CNTMuteSuccessBlock)success failure:(CNTFailureBlock)failure;

@end
