//
//  MediaLaunchObject.m
//  ConnectSDK
//
//  Created by Ibrahim Adnan on 1/19/15.
//  Copyright (c) 2015 LG Electronics. All rights reserved.
//

#import "MediaLaunchObject.h"

@implementation MediaLaunchObject

- (instancetype) initWithLaunchSession:(LaunchSession *)session andMediaControl:(id<MediaControl>)mediaControl
{
    return [self initWithLaunchSession:session andMediaControl:mediaControl andPlayListControl:nil];
}

- (instancetype) initWithLaunchSession:(LaunchSession *)session andMediaControl:(id<MediaControl>)mediaControl andPlayListControl:(id<PlayListControl>)playListControl
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
