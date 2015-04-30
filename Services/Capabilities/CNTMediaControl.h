//
//  CNTMediaControl.h
//  Connect SDK
//
//  Created by Jeremy White on 1/22/14.
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

#define kCNTMediaControlAny @"CNTMediaControl.Any"

#define kCNTMediaControlPlay @"CNTMediaControl.Play"
#define kCNTMediaControlPause @"CNTMediaControl.Pause"
#define kCNTMediaControlStop @"CNTMediaControl.Stop"
#define kCNTMediaControlDuration @"CNTMediaControl.Duration"
#define kCNTMediaControlRewind @"CNTMediaControl.Rewind"
#define kCNTMediaControlFastForward @"CNTMediaControl.FastForward"
#define kCNTMediaControlSeek @"CNTMediaControl.Seek"
#define kCNTMediaControlPlayState @"CNTMediaControl.PlayState"
#define kCNTMediaControlPlayStateSubscribe @"CNTMediaControl.PlayState.Subscribe"
#define kCNTMediaControlPosition @"CNTMediaControl.Position"
#define kCNTMediaControlMetadata @"CNTMediaControl.MetaData"
#define kCNTMediaControlMetadataSubscribe @"CNTMediaControl.MetaData.Subscribe"

#define kCNTMediaControlCapabilities @[\
    kCNTMediaControlPlay,\
    kCNTMediaControlPause,\
    kCNTMediaControlStop,\
    kCNTMediaControlDuration,\
    kCNTMediaControlRewind,\
    kCNTMediaControlFastForward,\
    kCNTMediaControlSeek,\
    kCNTMediaControlPlayState,\
    kCNTMediaControlPlayStateSubscribe,\
    kCNTMediaControlPosition,\
    kCNTMediaControlMetadata,\
    kCNTMediaControlMetadataSubscribe\
]

typedef enum {
    CNTMediaControlPlayStateUnknown,
    CNTMediaControlPlayStateIdle,
    CNTMediaControlPlayStatePlaying,
    CNTMediaControlPlayStatePaused,
    CNTMediaControlPlayStateBuffering,
    CNTMediaControlPlayStateFinished
} CNTMediaControlPlayState;

@protocol CNTMediaControl <NSObject>

/*!
 * Success block that is called upon any change in a media file's play state.
 *
 * @param playState Play state of the current media file
 */
typedef void (^CNTMediaPlayStateSuccessBlock)(CNTMediaControlPlayState playState);

/*!
 * Success block that is called upon successfully getting the media file's current playhead position.
 *
 * @param position Current playhead position of the current media file, in seconds
 */
typedef void (^CNTMediaPositionSuccessBlock)(NSTimeInterval position);

/*!
 * Success block that is called upon successfully getting the media file's duration.
 *
 * @param duration Duration of the current media file, in seconds
 */
typedef void (^CNTMediaDurationSuccessBlock)(NSTimeInterval duration);

- (id<CNTMediaControl>) mediaControl;
- (CNTCapabilityPriorityLevel) mediaControlPriority;

#pragma mark Play control
- (void) playWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) pauseWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) stopWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) rewindWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) fastForwardWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

@optional
- (void) seek:(NSTimeInterval)position success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

#pragma mark Play info
- (void) getDurationWithSuccess:(CNTMediaDurationSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) getPositionWithSuccess:(CNTMediaPositionSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void)getMediaMetaDataWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) getPlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure;
- (CNTServiceSubscription *)subscribePlayStateWithSuccess:(CNTMediaPlayStateSuccessBlock)success failure:(CNTFailureBlock)failure;
- (CNTServiceSubscription *)subscribeMediaInfoWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

@end
