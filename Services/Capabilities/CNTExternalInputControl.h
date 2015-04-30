//
//  CNTExternalInputControl.h
//  Connect SDK
//
//  Created by Jeremy White on 1/19/14.
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
#import "CNTExternalInputInfo.h"
#import "CNTAppInfo.h"

#define kCNTExternalInputControlAny @"CNTExternalInputControl.Any"

#define kCNTExternalInputControlPickerLaunch @"CNTExternalInputControl.Picker.Launch"
#define kCNTExternalInputControlPickerClose @"CNTExternalInputControl.Picker.Close"
#define kCNTExternalInputControlList @"CNTExternalInputControl.List"
#define kCNTExternalInputControlSet @"CNTExternalInputControl.Set"

#define kCNTExternalInputControlCapabilities @[\
    kCNTExternalInputControlPickerLaunch,\
    kCNTExternalInputControlPickerClose,\
    kCNTExternalInputControlList,\
    kCNTExternalInputControlSet\
]

@protocol CNTExternalInputControl <NSObject>

/*!
 * Success block that is called upon successfully getting the external input list.
 *
 * @param externalInputList Array containing an CNTExternalInputInfo object for each available external input on the device
 */
typedef void (^CNTExternalInputListSuccessBlock)(NSArray *externalInputList);

- (id<CNTExternalInputControl>)externalInputControl;
- (CNTCapabilityPriorityLevel)externalInputControlPriority;

- (void)launchInputPickerWithSuccess:(CNTAppLaunchSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void)closeInputPicker:(CNTLaunchSession *)launchSession success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) getExternalInputListWithSuccess:(CNTExternalInputListSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) setExternalInput:(CNTExternalInputInfo *)externalInputInfo success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

@end
