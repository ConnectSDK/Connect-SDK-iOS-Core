//
//  WebOSTVServiceMouse.h
//  Connect SDK
//
//  Created by Jeremy White on 1/3/14.
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
#import "Capability.h"

typedef enum {
WebOSTVMouseButtonPower = 1001,
WebOSTVMouseButtonUp = 1002,
WebOSTVMouseButtonDown = 1003,
WebOSTVMouseButtonRight = 1004,
WebOSTVMouseButtonLeft = 1005,
WebOSTVMouseButtonMenu = 1006,
WebOSTVMouseButtonHome = 1007,
WebOSTVMouseButtonBack = 1008,
WebOSTVMouseButtonExit = 1009,
WebOSTVMouseButtonOk = 1010,
WebOSTVMouseButtonVolumeUp = 1011,
WebOSTVMouseButtonVolumeDown = 1012,
WebOSTVMouseButtonChannelUp = 1013,
WebOSTVMouseButtonChannelDown = 1014,
WebOSTVMouseButtonSource = 1015,
WebOSTVMouseButtonZero = 1016,
WebOSTVMouseButtonOne = 1017,
WebOSTVMouseButtonTwo = 1018,
WebOSTVMouseButtonThree = 1019,
WebOSTVMouseButtonFour = 1020,
WebOSTVMouseButtonFive = 1021,
WebOSTVMouseButtonSix = 1022,
WebOSTVMouseButtonSeven = 1023,
WebOSTVMouseButtonEight = 1024,
WebOSTVMouseButtonNine = 1025,
WebOSTVMouseButtonMute = 1026,
WebOSTVMouseButtonPlay = 1027,
WebOSTVMouseButtonPause = 1028,
WebOSTVMouseButtonNext = 1029,
WebOSTVMouseButtonPrev = 1030
} WebOSTVMouseButton;


@interface WebOSTVServiceMouse : NSObject

- (instancetype) initWithSocket:(NSString*)socket success:(SuccessBlock)success failure:(FailureBlock)failure;
- (void) move:(CGVector)distance;
- (void) scroll:(CGVector)distance;
- (void) click;
- (void) button:(WebOSTVMouseButton)keyName;
- (void) disconnect;

@end
