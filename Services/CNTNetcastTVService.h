//
//  CNTNetcastTVService.h
//  Connect SDK
//
//  Created by Jeremy White on 12/2/13.
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

#define kCNTConnectSDKNetcastTVServiceId @"Netcast TV"

#import <UIKit/UIKit.h>
#import "CNTDeviceService.h"
#import "CNTLauncher.h"
#import "CNTNetcastTVServiceConfig.h"
#import "CNTDIALService.h"
#import "CNTDLNAService.h"
#import "CNTMediaControl.h"
#import "CNTExternalInputControl.h"
#import "CNTVolumeControl.h"
#import "CNTTVControl.h"
#import "CNTKeyControl.h"
#import "CNTMouseControl.h"
#import "CNTTextInputControl.h"
#import "CNTPowerControl.h"

@interface CNTNetcastTVService : CNTDeviceService <CNTLauncher, CNTMediaPlayer, CNTMediaControl, CNTVolumeControl, CNTTVControl, CNTKeyControl, CNTMouseControl, CNTPowerControl, CNTExternalInputControl, CNTTextInputControl>

// @cond INTERNAL
/// The base class' @c serviceConfig property downcast to
/// @c CNTNetcastTVServiceConfig if possible, or nil.
@property (nonatomic, strong) CNTNetcastTVServiceConfig *netcastTVServiceConfig;

// these objects are maintained to provide certain functionality without requiring pairing
@property (nonatomic, strong, readonly) CNTDIALService *dialService;
@property (nonatomic, strong, readonly) CNTDLNAService *dlnaService;

// Defined at http://developer.lgappstv.com/TV_HELP/topic/lge.tvsdk.references.book/html/UDAP/UDAP/Annex%20A%20Table%20of%20virtual%20key%20codes%20on%20remote%20Controller.htm#_Annex_A_Table
enum {
    CNTNetcastTVKeyCodePower = 1,
    CNTNetcastTVKeyCodeNumber0 = 2,
    CNTNetcastTVKeyCodeNumber1 = 3,
    CNTNetcastTVKeyCodeNumber2 = 4,
    CNTNetcastTVKeyCodeNumber3 = 5,
    CNTNetcastTVKeyCodeNumber4 = 6,
    CNTNetcastTVKeyCodeNumber5 = 7,
    CNTNetcastTVKeyCodeNumber6 = 8,
    CNTNetcastTVKeyCodeNumber7 = 9,
    CNTNetcastTVKeyCodeNumber8 = 10,
    CNTNetcastTVKeyCodeNumber9 = 11,
    CNTNetcastTVKeyCodeUp = 12,
    CNTNetcastTVKeyCodeDown = 13,
    CNTNetcastTVKeyCodeLeft = 14,
    CNTNetcastTVKeyCodeRight = 15,
    CNTNetcastTVKeyCodeOK = 20,
    CNTNetcastTVKeyCodeHome = 21,
    CNTNetcastTVKeyCodeMenu = 22,
    CNTNetcastTVKeyCodeBack = 23,
    CNTNetcastTVKeyCodeVolumeUp = 24,
    CNTNetcastTVKeyCodeVolumeDown = 25,
    CNTNetcastTVKeyCodeMute = 26, // Toggle
    CNTNetcastTVKeyCodeChannelUp = 27,
    CNTNetcastTVKeyCodeChannelDown = 28,
    CNTNetcastTVKeyCodeBlue = 29,
    CNTNetcastTVKeyCodeGreen = 30,
    CNTNetcastTVKeyCodeRed = 31,
    CNTNetcastTVKeyCodeYellow = 32,
    CNTNetcastTVKeyCodePlay = 33,
    CNTNetcastTVKeyCodePause = 34,
    CNTNetcastTVKeyCodeStop = 35,
    CNTNetcastTVKeyCodeFastForward = 36,
    CNTNetcastTVKeyCodeRewind = 37,
    CNTNetcastTVKeyCodeSkipForward = 38,
    CNTNetcastTVKeyCodeSkipBackward = 39,
    CNTNetcastTVKeyCodeRecord = 40,
    CNTNetcastTVKeyCodeRecordingList = 41,
    CNTNetcastTVKeyCodeRepeat = 42,
    CNTNetcastTVKeyCodeLiveTV = 43,
    CNTNetcastTVKeyCodeEPG = 44,
    CNTNetcastTVKeyCodeCurrentProgramInfo = 45,
    CNTNetcastTVKeyCodeAspectRatio = 46,
    CNTNetcastTVKeyCodeExternalInput = 47,
    CNTNetcastTVKeyCodePIP = 48,
    CNTNetcastTVKeyCodeSubtitle = 49, // Toggle
    CNTNetcastTVKeyCodeProgramList = 50,
    CNTNetcastTVKeyCodeTeleText = 51,
    CNTNetcastTVKeyCodeMark = 52,
    CNTNetcastTVKeyCode3DVideo = 400,
    CNTNetcastTVKeyCode3DLR = 401,
    CNTNetcastTVKeyCodeDash = 402, // (-)
    CNTNetcastTVKeyCodePreviousChannel = 403,
    CNTNetcastTVKeyCodeFavoriteChannel = 404,
    CNTNetcastTVKeyCodeQuickMenu = 405,
    CNTNetcastTVKeyCodeTextOption = 406,
    CNTNetcastTVKeyCodeAudioDescription = 407,
    CNTNetcastTVKeyCodeNetcast = 408,
    CNTNetcastTVKeyCodeEnergySaving = 409,
    CNTNetcastTVKeyCodeAVMode = 410,
    CNTNetcastTVKeyCodeSIMPLINK = 411,
    CNTNetcastTVKeyCodeExit = 412,
    CNTNetcastTVKeyCodeReservationProgramsList = 413,
    CNTNetcastTVKeyCodePIPChannelUp = 414,
    CNTNetcastTVKeyCodePIPChannelDown = 415,
    CNTNetcastTVKeyCodeVideoSwitch = 416,
    CNTNetcastTVKeyCodeMyApps = 417
};

typedef NSUInteger CNTNetcastTVKeyCode;

- (void) pairWithData:(NSString *)pairingData;
// @endcond

@end
