//
//  MediaLaunchObject.h
//  ConnectSDK
//
//  Created by Ibrahim Adnan on 1/19/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MediaControl.h"
#import "PlayListControl.h"
#import "LaunchSession.h"

@interface MediaLaunchObject : NSObject

/*! MediaControl object of Media player*/
@property (nonatomic, strong) id<MediaControl> mediaControl;

/*! PlayList Control Object of Media player*/
@property (nonatomic, strong) id<PlayListControl> playListControl;

/*! Launch Session object of Media player*/
@property (nonatomic, strong) LaunchSession *session;


/*
 * Creates an instance of MediaLaunch with given property values.
 *
 * @param launchSession LaunchSession to allow closing this media player
 * @param mediaControl MediaControl object used to control playback
 * @param playListControl PlayListControl object used to control playlist
 */
- (instancetype) initLaunchSession:(LaunchSession *)session withMediaControl:(id<MediaControl>)mediaControl;
- (instancetype) initLaunchSession:(LaunchSession *)session withMediaControl:(id<MediaControl>)mediaControl andPlayListControl:(id<PlayListControl>)playListControl;

@end
