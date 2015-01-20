//
//  MediaLaunchObject.m
//  ConnectSDK
//
//  Created by Ibrahim Adnan on 1/19/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "MediaLaunchObject.h"

@implementation MediaLaunchObject

// return nil here so that we force users to have URL and mime-type
- (instancetype) init
{
    return nil;
}

- (instancetype) initLaunchSession:(LaunchSession *)session withMediaControl:(id<MediaControl>)mediaControl
{
    self = [super init];
    
    if (self)
    {
        self.session = session;
        self.mediaControl = mediaControl;
    }
    
    return self;
}

- (instancetype) initLaunchSession:(LaunchSession *)session withMediaControl:(id<MediaControl>)mediaControl andPlayListControl:(id<PlayListControl>)playListControl
{
    self = [super init];
    
    if (self)
    {
        self.session = session;
        self.mediaControl = mediaControl;
        self.playListControl = playListControl;
    }
    
    return self;
}

@end
