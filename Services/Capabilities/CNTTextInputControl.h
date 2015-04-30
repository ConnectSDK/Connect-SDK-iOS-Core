//
//  CNTTextInputControl.h
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
#import "CNTTextInputStatusInfo.h"
#import "CNTServiceSubscription.h"

#define kCNTTextInputControlAny @"CNTTextInputControl.Any"

#define kCNTTextInputControlSendText @"CNTTextInputControl.Send.Text"
#define kCNTTextInputControlSendEnter @"CNTTextInputControl.Send.Enter"
#define kCNTTextInputControlSendDelete @"CNTTextInputControl.Send.Delete"
#define kCNTTextInputControlSubscribe @"CNTTextInputControl.Subscribe"

#define kCNTTextInputControlCapabilities @[\
    kCNTTextInputControlSendText,\
    kCNTTextInputControlSendEnter,\
    kCNTTextInputControlSendDelete,\
    kCNTTextInputControlSubscribe\
]

@protocol CNTTextInputControl <NSObject>

/*!
 * Response block that is fired on any change of keyboard visibility.
 *
 * @param textInputStatusInfo provides keyboard type & visibility information
 */
typedef void (^CNTTextInputStatusInfoSuccessBlock)(CNTTextInputStatusInfo *textInputStatusInfo);

- (id<CNTTextInputControl>) textInputControl;
- (CNTCapabilityPriorityLevel) textInputControlPriority;

- (CNTServiceSubscription *) subscribeTextInputStatusWithSuccess:(CNTTextInputStatusInfoSuccessBlock)success failure:(CNTFailureBlock)failure;

- (void) sendText:(NSString *)input success:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) sendEnterWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;
- (void) sendDeleteWithSuccess:(CNTSuccessBlock)success failure:(CNTFailureBlock)failure;

@end
