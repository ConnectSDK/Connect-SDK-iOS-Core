//
//  CNTMediaPlayer.h
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
#import "CNTLauncher.h"
#import "CNTMediaControl.h"
#import "CNTMediaInfo.h"
#import "CNTMediaLaunchObject.h"

#define kCNTMediaPlayerAny @"CNTMediaPlayer.Any"

#define kCNTMediaPlayerDisplayImage @"CNTMediaPlayer.Display.Image"
#define kCNTMediaPlayerPlayVideo @"CNTMediaPlayer.Play.Video"
#define kCNTMediaPlayerPlayAudio @"CNTMediaPlayer.Play.Audio"
#define kCNTMediaPlayerPlayPlaylist @"CNTMediaPlayer.Play.Playlist"
#define kCNTMediaPlayerClose @"CNTMediaPlayer.Close"
#define kCNTMediaPlayerMetaDataTitle @"CNTMediaPlayer.MetaData.Title"
#define kCNTMediaPlayerMetaDataDescription @"CNTMediaPlayer.MetaData.Description"
#define kCNTMediaPlayerMetaDataThumbnail @"CNTMediaPlayer.MetaData.Thumbnail"
#define kCNTMediaPlayerMetaDataMimeType @"CNTMediaPlayer.MetaData.MimeType"

#define kCNTMediaPlayerCapabilities @[\
    kCNTMediaPlayerDisplayImage,\
    kCNTMediaPlayerPlayVideo,\
    kCNTMediaPlayerPlayAudio,\
    kCNTMediaPlayerClose,\
    kCNTMediaPlayerMetaDataTitle,\
    kCNTMediaPlayerMetaDataDescription,\
    kCNTMediaPlayerMetaDataThumbnail,\
    kCNTMediaPlayerMetaDataMimeType\
]

@protocol CNTMediaPlayer <NSObject>

/*!
 * Success block that is called upon successfully playing/displaying a media file.
 *
 * @param launchSession CNTLaunchSession to allow closing this media player
 * @param mediaControl CNTMediaControl object used to control playback
 */
typedef void (^CNTMediaPlayerDisplaySuccessBlock)(CNTLaunchSession *launchSession, id<CNTMediaControl> mediaControl);
typedef void (^CNTMediaPlayerSuccessBlock)(CNTMediaLaunchObject *mediaLanchObject);


- (id<CNTMediaPlayer>) mediaPlayer;
- (CNTCapabilityPriorityLevel) mediaPlayerPriority;

- (void) displayImage:(NSURL *)imageURL
             iconURL:(NSURL *)iconURL
               title:(NSString *)title
         description:(NSString *)description
            mimeType:(NSString *)mimeType
             success:(CNTMediaPlayerDisplaySuccessBlock)success
             failure:(CNTFailureBlock)failure
__attribute__((deprecated));

- (void) displayImage:(CNTMediaInfo *)mediaInfo
              success:(CNTMediaPlayerDisplaySuccessBlock)success
              failure:(CNTFailureBlock)failure
__attribute__((deprecated));

- (void) displayImageWithMediaInfo:(CNTMediaInfo *)mediaInfo
              success:(CNTMediaPlayerSuccessBlock)success
              failure:(CNTFailureBlock)failure;

- (void) playMedia:(NSURL *)mediaURL
           iconURL:(NSURL *)iconURL
             title:(NSString *)title
       description:(NSString *)description
          mimeType:(NSString *)mimeType
        shouldLoop:(BOOL)shouldLoop
           success:(CNTMediaPlayerDisplaySuccessBlock)success
           failure:(CNTFailureBlock)failure
__attribute__((deprecated));

- (void) playMedia:(CNTMediaInfo *)mediaInfo
        shouldLoop:(BOOL)shouldLoop
           success:(CNTMediaPlayerDisplaySuccessBlock)success
           failure:(CNTFailureBlock)failure
__attribute__((deprecated));

- (void) playMediaWithMediaInfo:(CNTMediaInfo *)mediaInfo
        shouldLoop:(BOOL)shouldLoop
           success:(CNTMediaPlayerSuccessBlock)success
                        failure:(CNTFailureBlock)failure;

- (void) closeMedia:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

@end
