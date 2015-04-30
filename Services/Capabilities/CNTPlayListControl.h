//
//  CNTPlayListControl.h
//  ConnectSDK
//
//  Created by Ibrahim Adnan on 1/19/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
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

#import <Foundation/Foundation.h>

@protocol CNTPlayListControl <NSObject>

#define kCNTPlayListControlNext @"CNTPlayListControl.Next"
#define kCNTPlayListControlPrevious @"CNTPlayListControl.Previous"
#define kCNTPlayListControlJumpTrack @"CNTPlayListControl.JumpTrack"

#define kCNTPlayListControlCapabilities @[\
kCNTMediaControlNext,\
kCNTMediaControlPrevious,\
kCNTMediaControlJumpTrack\
]

- (id<CNTPlayListControl>) playListControl;
- (CNTCapabilityPriorityLevel) playListControlPriority;

#pragma mark Playlist controls
/*!
 * Plays the next track in the playlist
 */
- (void) playNextWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
/*!
 * Plays the previous track in the playlist
 * @param device CNTConnectableDevice that has been disconnected.
 */
- (void) playPreviousWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
/*!
 * Jumps to track in the playlist
 *
 * @param index NSInteger a zero based index parameter.
 */
- (void)jumpToTrackWithIndex:(NSInteger)index success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;


@end
