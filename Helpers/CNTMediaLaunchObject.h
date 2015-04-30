//
//  CNTMediaLaunchObject.h
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
//

#import <Foundation/Foundation.h>
#import "CNTMediaControl.h"
#import "CNTPlayListControl.h"
#import "CNTLaunchSession.h"

/*! CNTMediaLaunchObject is a container object which holds CNTLaunchSession object,CNTMediaControl object/or and CNTPlayListControl object*/
@interface CNTMediaLaunchObject : NSObject

/*! CNTMediaControl object of Media player*/
@property (nonatomic, strong) id<CNTMediaControl> mediaControl;

/*! PlayList Control Object of Media player*/
@property (nonatomic, strong) id<CNTPlayListControl> playListControl;

/*! Launch Session object of Media player*/
@property (nonatomic, strong) CNTLaunchSession *session;


/*!
 * Creates an instance of CNTMediaLaunchObject with given property values.
 *
 * @param launchSession CNTLaunchSession to allow closing this media player
 * @param mediaControl CNTMediaControl object used to control playback
 * @param playListControl CNTPlayListControl object used to control playlist
 */
- (instancetype) initWithLaunchSession:(CNTLaunchSession *)session andMediaControl:(id<CNTMediaControl>)mediaControl;
- (instancetype) initWithLaunchSession:(CNTLaunchSession *)session andMediaControl:(id<CNTMediaControl>)mediaControl andPlayListControl:(id<CNTPlayListControl>)playListControl;

@end
