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

#define kMediaPlayerAny @"MediaPlayer.Any"

#define kMediaPlayerDisplayImage @"MediaPlayer.Display.Image"
#define kMediaPlayerPlayVideo @"MediaPlayer.Play.Video"
#define kMediaPlayerPlayAudio @"MediaPlayer.Play.Audio"
#define kMediaPlayerPlayPlaylist @"MediaPlayer.Play.Playlist"
#define kMediaPlayerClose @"MediaPlayer.Close"
#define kMediaPlayerMetaDataTitle @"MediaPlayer.MetaData.Title"
#define kMediaPlayerMetaDataDescription @"MediaPlayer.MetaData.Description"
#define kMediaPlayerMetaDataThumbnail @"MediaPlayer.MetaData.Thumbnail"
#define kMediaPlayerMetaDataMimeType @"MediaPlayer.MetaData.MimeType"

#define kMediaPlayerCapabilities @[\
    kMediaPlayerDisplayImage,\
    kMediaPlayerPlayVideo,\
    kMediaPlayerPlayAudio,\
    kMediaPlayerClose,\
    kMediaPlayerMetaDataTitle,\
    kMediaPlayerMetaDataDescription,\
    kMediaPlayerMetaDataThumbnail,\
    kMediaPlayerMetaDataMimeType\
]

@protocol CNTMediaPlayer <NSObject>

/*!
 * Success block that is called upon successfully playing/displaying a media file.
 *
 * @param launchSession CNTLaunchSession to allow closing this media player
 * @param mediaControl CNTMediaControl object used to control playback
 */
typedef void (^MediaPlayerDisplaySuccessBlock)(CNTLaunchSession *launchSession, id<CNTMediaControl> mediaControl);
typedef void (^MediaPlayerSuccessBlock)(CNTMediaLaunchObject *mediaLanchObject);


- (id<CNTMediaPlayer>) mediaPlayer;
- (CapabilityPriorityLevel) mediaPlayerPriority;

- (void) displayImage:(NSURL *)imageURL
             iconURL:(NSURL *)iconURL
               title:(NSString *)title
         description:(NSString *)description
            mimeType:(NSString *)mimeType
             success:(MediaPlayerDisplaySuccessBlock)success
             failure:(FailureBlock)failure
__attribute__((deprecated));

- (void) displayImage:(CNTMediaInfo *)mediaInfo
              success:(MediaPlayerDisplaySuccessBlock)success
              failure:(FailureBlock)failure
__attribute__((deprecated));

- (void) displayImageWithMediaInfo:(CNTMediaInfo *)mediaInfo
              success:(MediaPlayerSuccessBlock)success
              failure:(FailureBlock)failure;

- (void) playMedia:(NSURL *)mediaURL
           iconURL:(NSURL *)iconURL
             title:(NSString *)title
       description:(NSString *)description
          mimeType:(NSString *)mimeType
        shouldLoop:(BOOL)shouldLoop
           success:(MediaPlayerDisplaySuccessBlock)success
           failure:(FailureBlock)failure
__attribute__((deprecated));

- (void) playMedia:(CNTMediaInfo *)mediaInfo
        shouldLoop:(BOOL)shouldLoop
           success:(MediaPlayerDisplaySuccessBlock)success
           failure:(FailureBlock)failure
__attribute__((deprecated));

- (void) playMediaWithMediaInfo:(CNTMediaInfo *)mediaInfo
        shouldLoop:(BOOL)shouldLoop
           success:(MediaPlayerSuccessBlock)success
                        failure:(FailureBlock)failure;

- (void) closeMedia:(CNTLaunchSession *)launchSession success:(SuccessBlock)success failure:(FailureBlock)failure;

@end
